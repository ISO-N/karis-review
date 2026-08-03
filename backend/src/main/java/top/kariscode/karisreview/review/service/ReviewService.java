package top.kariscode.karisreview.review.service;

import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import top.kariscode.karisreview.auth.entity.User;
import top.kariscode.karisreview.auth.repository.UserRepository;
import top.kariscode.karisreview.card.entity.Card;
import top.kariscode.karisreview.card.repository.CardRepository;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.common.util.DateUtils;
import top.kariscode.karisreview.log.service.UserLogService;
import top.kariscode.karisreview.review.dto.RateRequest;
import top.kariscode.karisreview.review.dto.RateResponse;
import top.kariscode.karisreview.review.dto.ReviewCardResponse;
import top.kariscode.karisreview.review.dto.ReviewSessionCreateRequest;
import top.kariscode.karisreview.review.dto.ReviewSessionPageResponse;
import top.kariscode.karisreview.review.dto.ReviewSyncItem;
import top.kariscode.karisreview.review.dto.ReviewSyncItemResult;
import top.kariscode.karisreview.review.dto.ReviewSyncRequest;
import top.kariscode.karisreview.review.dto.ReviewSyncResponse;
import top.kariscode.karisreview.review.entity.ReviewLog;
import top.kariscode.karisreview.review.entity.ReviewQueueItem;
import top.kariscode.karisreview.review.entity.ReviewSession;
import top.kariscode.karisreview.review.repository.ReviewLogRepository;
import top.kariscode.karisreview.review.repository.ReviewQueueItemRepository;
import top.kariscode.karisreview.review.repository.ReviewSessionRepository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Service
public class ReviewService {

    private static final int DEFAULT_PAGE_SIZE = 10;
    private static final int MAX_PAGE_SIZE = 50;
    private static final int MAX_LEGACY_QUEUE_SIZE = 500;
    private static final int SESSION_TTL_HOURS = 24;

    private final CardRepository cardRepository;
    private final ReviewLogRepository reviewLogRepository;
    private final UserRepository userRepository;
    private final SchedulingEngine schedulingEngine;
    private final ReviewSessionRepository reviewSessionRepository;
    private final ReviewQueueItemRepository reviewQueueItemRepository;
    private final UserLogService userLogService;

    public ReviewService(CardRepository cardRepository,
                         ReviewLogRepository reviewLogRepository,
                         UserRepository userRepository,
                         SchedulingEngine schedulingEngine,
                         ReviewSessionRepository reviewSessionRepository,
                         ReviewQueueItemRepository reviewQueueItemRepository,
                         UserLogService userLogService) {
        this.cardRepository = cardRepository;
        this.reviewLogRepository = reviewLogRepository;
        this.userRepository = userRepository;
        this.schedulingEngine = schedulingEngine;
        this.reviewSessionRepository = reviewSessionRepository;
        this.reviewQueueItemRepository = reviewQueueItemRepository;
        this.userLogService = userLogService;
    }

    public List<ReviewCardResponse> getDueCards(UUID userId, UUID deckId) {
        return getDueCards(userId, deckId, MAX_LEGACY_QUEUE_SIZE);
    }

    public List<ReviewCardResponse> getDueCards(UUID userId, UUID deckId, int limit) {
        List<Card> queue = buildDueQueue(userId, deckId);
        return toLimitedQueue(queue, limit);
    }

    public List<ReviewCardResponse> getNewCards(UUID userId, UUID deckId) {
        return getNewCards(userId, deckId, DEFAULT_PAGE_SIZE);
    }

    public List<ReviewCardResponse> getNewCards(UUID userId, UUID deckId, int limit) {
        List<Card> queue = cardRepository.findNewCards(userId, deckId);
        return toLimitedQueue(queue, limit);
    }

    @Transactional
    public ReviewSessionPageResponse createSession(UUID userId, ReviewSessionCreateRequest request) {
        String mode = request.getMode();
        UUID deckId = request.getDeckId();
        int batchSize = request.getBatchSize() == null
                ? DEFAULT_PAGE_SIZE
                : Math.max(1, Math.min(MAX_PAGE_SIZE, request.getBatchSize()));

        List<Card> queue = "new".equals(mode)
                ? cardRepository.findNewCards(userId, deckId)
                : buildDueQueue(userId, deckId);

        ReviewSession session = new ReviewSession();
        session.setUserId(userId);
        session.setMode(mode);
        session.setDeckId(deckId);
        session.setBatchSize(batchSize);
        session.setTotalCount(queue.size());
        session.setExpiresAt(DateUtils.now().plusHours(SESSION_TTL_HOURS));
        session = reviewSessionRepository.save(session);

        List<ReviewQueueItem> items = new ArrayList<>(queue.size());
        for (int i = 0; i < queue.size(); i++) {
            ReviewQueueItem item = new ReviewQueueItem();
            item.setSessionId(session.getId());
            item.setUserId(userId);
            item.setPosition(i);
            item.setCardId(queue.get(i).getId());
            items.add(item);
        }
        reviewQueueItemRepository.saveAll(items);

        return buildPage(userId, session, 0, batchSize);
    }

    @Transactional(readOnly = true)
    public ReviewSessionPageResponse getSessionPage(UUID userId, UUID sessionId, int cursor, int limit) {
        ReviewSession session = findSession(userId, sessionId);
        int safeLimit = Math.max(1, Math.min(MAX_PAGE_SIZE, limit));
        int start = Math.max(0, cursor);
        int end = Math.min(start + safeLimit, session.getTotalCount());

        if (end <= start) {
            return new ReviewSessionPageResponse(
                    session.getId(), session.getMode(), session.getDeckId(),
                    session.getBatchSize(), session.getTotalCount(), session.getTotalCount(),
                    false, List.of());
        }

        List<ReviewQueueItem> items = reviewQueueItemRepository
                .findBySessionIdAndPositionGreaterThanEqualOrderByPositionAsc(
                        sessionId, start, PageRequest.of(0, end - start));
        Map<UUID, Card> cardMap = loadCardsByIds(items.stream().map(ReviewQueueItem::getCardId).toList());

        List<ReviewCardResponse> cards = new ArrayList<>();
        for (ReviewQueueItem item : items) {
            Card card = cardMap.get(item.getCardId());
            if (card != null && userId.equals(card.getUserId())) {
                cards.add(toReviewCardResponse(card));
            }
        }

        boolean hasMore = end < session.getTotalCount() && !cards.isEmpty();
        if (cards.isEmpty() && end < session.getTotalCount()) {
            end = session.getTotalCount();
        }
        return new ReviewSessionPageResponse(
                session.getId(), session.getMode(), session.getDeckId(),
                session.getBatchSize(), session.getTotalCount(), end, hasMore, cards);
    }

    @Transactional
    public void deleteSession(UUID userId, UUID sessionId) {
        ReviewSession session = findSession(userId, sessionId);
        reviewSessionRepository.delete(session);
    }

    @Transactional
    public ReviewSyncResponse syncRatings(UUID userId, ReviewSyncRequest request) {
        List<ReviewSyncItemResult> results = new ArrayList<>();
        int synced = 0;
        int conflicts = 0;
        int missing = 0;

        for (ReviewSyncItem item : request.getItems()) {
            String clientRequestId = item.getClientRequestId();
            Optional<ReviewLog> existing = clientRequestId == null || clientRequestId.isBlank()
                    ? Optional.empty()
                    : reviewLogRepository.findByUserIdAndClientRequestId(userId, clientRequestId);

            if (existing.isPresent()) {
                ReviewLog log = existing.get();
                if (log.getCardId().equals(item.getCardId()) && log.getRating().equals(item.getRating())) {
                    results.add(new ReviewSyncItemResult(
                            clientRequestId, "ALREADY_SYNCED", null));
                    continue;
                }
                results.add(new ReviewSyncItemResult(
                        clientRequestId, "CONFLICT", null));
                conflicts++;
                continue;
            }

            Card card = cardRepository.findByIdAndUserIdForUpdate(item.getCardId(), userId)
                    .orElse(null);
            if (card == null) {
                results.add(new ReviewSyncItemResult(
                        clientRequestId, "CARD_NOT_FOUND", null));
                missing++;
                continue;
            }

            if (card.getReviewVersion() != item.getReviewVersion()) {
                results.add(new ReviewSyncItemResult(
                        clientRequestId, "CONFLICT", toReviewCardResponse(card)));
                conflicts++;
                continue;
            }

            applyRating(
                    userId, item.getCardId(), card, item.getRating(),
                    clientRequestId, DateUtils.toBusinessLocalDateTime(item.getRatedAt()));
            results.add(new ReviewSyncItemResult(
                    clientRequestId, "SYNCED", null));
            synced++;
        }

        userLogService.log(userId, "INFO", "SYNC", String.format(
                "Review sync: %d synced, %d conflicts, %d missing", synced, conflicts, missing));

        return new ReviewSyncResponse(synced, conflicts, missing, results);
    }

    @Transactional
    public RateResponse rateCard(UUID userId, UUID cardId, RateRequest request) {
        String clientRequestId = request.getClientRequestId();
        if (clientRequestId != null && !clientRequestId.isBlank()) {
            Optional<ReviewLog> existing = reviewLogRepository
                    .findByUserIdAndClientRequestId(userId, clientRequestId);
            if (existing.isPresent()) {
                ReviewLog log = existing.get();
                if (!log.getCardId().equals(cardId) || !log.getRating().equals(request.getRating())) {
                    userLogService.log(userId, "WARN", "REVIEW", String.format(
                            "Rating conflict: card=%s, clientRequestId=%s, expected=%s/%s, got=%s/%s",
                            cardId, clientRequestId,
                            log.getCardId(), log.getRating(),
                            cardId, request.getRating()));
                    throw new BusinessException(409, "review.conflict.request");
                }
                Card current = cardRepository.findByIdAndUserId(cardId, userId)
                        .orElseThrow(() -> new BusinessException(404, "review.card.notfound"));
                return new RateResponse(
                        cardId, log.getRating(), log.getStageBefore(), log.getStageAfter(),
                        null, false, 0, 0, current.getReviewVersion());
            }
        }

        Card card = cardRepository.findByIdAndUserIdForUpdate(cardId, userId)
                .orElseThrow(() -> new BusinessException(404, "review.card.notfound"));

        if (request.getReviewVersion() != null
                && request.getReviewVersion() != card.getReviewVersion()) {
            userLogService.log(userId, "WARN", "REVIEW", String.format(
                    "Version conflict: card=%s, expected=%d, got=%d",
                    cardId, card.getReviewVersion(), request.getReviewVersion()));
            throw new BusinessException(409, "review.conflict.version");
        }

        return applyRating(userId, cardId, card, request.getRating(),
                clientRequestId, DateUtils.now());
    }

    @Scheduled(fixedDelay = 3600000)
    @Transactional
    public void cleanupExpiredSessions() {
        reviewSessionRepository.deleteExpired(DateUtils.now());
    }

    private RateResponse applyRating(UUID userId, UUID cardId, Card card,
                                     String rating, String clientRequestId,
                                     LocalDateTime reviewedAt) {
        LocalTime refreshTime = getRefreshTime(userId);
        boolean wasNewCard = card.getStage() == 0 && !card.isLearningMode();
        SchedulingEngine.RatingResult result;
        switch (rating) {
            case "FORGET" -> result = schedulingEngine.rateForget(card, refreshTime);
            case "VAGUE" -> result = schedulingEngine.rateVague(card, refreshTime);
            case "FAMILIAR" -> result = schedulingEngine.rateFamiliar(card, refreshTime);
            default -> throw new BusinessException(400, "review.rating.invalid");
        }

        card = cardRepository.save(card);

        ReviewLog log = new ReviewLog();
        log.setCardId(cardId);
        log.setUserId(userId);
        log.setRating(rating);
        log.setStageBefore(result.getStageBefore());
        log.setStageAfter(result.getStageAfter());
        log.setNewCard(wasNewCard);
        log.setClientRequestId(clientRequestId);
        log.setReviewedAt(reviewedAt == null ? DateUtils.now() : reviewedAt);
        reviewLogRepository.save(log);

        LocalDate today = DateUtils.calculateToday(refreshTime);
        int nextIntervalDays = result.getNextReviewDate() == null
                ? 0
                : (int) ChronoUnit.DAYS.between(today, result.getNextReviewDate());
        return new RateResponse(
                cardId, rating,
                result.getStageBefore(),
                result.getStageAfter(),
                result.getNextReviewDate(),
                result.isLearningMode(),
                result.getConsecutiveFamiliar(),
                nextIntervalDays,
                card.getReviewVersion());
    }

    private List<Card> buildDueQueue(UUID userId, UUID deckId) {
        LocalTime refreshTime = getRefreshTime(userId);
        LocalDate today = DateUtils.calculateToday(refreshTime);
        List<Card> dueCards = cardRepository.findDueCards(userId, today, deckId);
        List<Card> learningCards = cardRepository.findLearningModeCards(userId, today, deckId);
        return interleaveLearningCards(dueCards, learningCards);
    }

    private List<Card> interleaveLearningCards(List<Card> dueCards, List<Card> learningCards) {
        List<Card> queue = new ArrayList<>(dueCards);
        if (learningCards.isEmpty()) {
            return queue;
        }

        List<Card> sortedLearning = learningCards.stream()
                .sorted(Comparator.comparingInt(Card::getLearningStep)
                        .thenComparing(Card::getCreatedAt))
                .toList();

        for (Card card : sortedLearning) {
            int offset = 1 << card.getLearningStep();
            int position = Math.min(offset, queue.size());
            queue.add(position, card);
        }
        return queue;
    }

    private List<ReviewCardResponse> toLimitedQueue(List<Card> queue, int limit) {
        int safeLimit = Math.max(1, Math.min(MAX_LEGACY_QUEUE_SIZE, limit));
        return queue.stream()
                .limit(safeLimit)
                .map(this::toReviewCardResponse)
                .toList();
    }

    private ReviewSessionPageResponse buildPage(UUID userId, ReviewSession session, int cursor, int limit) {
        return getSessionPage(userId, session.getId(), cursor, limit);
    }

    private ReviewSession findSession(UUID userId, UUID sessionId) {
        ReviewSession session = reviewSessionRepository.findByIdAndUserId(sessionId, userId)
                .orElseThrow(() -> new BusinessException(404, "review.session.notfound"));
        if (session.getExpiresAt().isBefore(DateUtils.now())) {
            throw new BusinessException(410, "review.session.expired");
        }
        return session;
    }

    private Map<UUID, Card> loadCardsByIds(List<UUID> ids) {
        Map<UUID, Card> map = new HashMap<>();
        if (ids.isEmpty()) {
            return map;
        }
        for (Card card : cardRepository.findAllById(ids)) {
            map.put(card.getId(), card);
        }
        return map;
    }

    private ReviewCardResponse toReviewCardResponse(Card card) {
        return new ReviewCardResponse(
                card.getId(), card.getDeckId(),
                card.getFront(), card.getBack(),
                card.getStage(), card.isLearningMode(),
                card.getConsecutiveFamiliar(),
                card.getReentryStage(),
                card.getNextReviewDate(),
                card.getLearningStep(),
                card.getReviewVersion());
    }

    private LocalTime getRefreshTime(UUID userId) {
        return userRepository.findById(userId)
                .map(User::getRefreshTime)
                .orElse(LocalTime.of(4, 0));
    }
}