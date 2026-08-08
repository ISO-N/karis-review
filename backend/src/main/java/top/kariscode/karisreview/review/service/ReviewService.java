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
import java.util.stream.Collectors;

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
        return toLimitedQueue(buildNewQueue(userId, deckId), limit);
    }

    @Transactional
    public ReviewSessionPageResponse createSession(UUID userId, ReviewSessionCreateRequest request) {
        String mode = request.getMode();
        UUID deckId = request.getDeckId();
        int batchSize = request.getBatchSize() == null
                ? DEFAULT_PAGE_SIZE
                : Math.max(1, Math.min(MAX_PAGE_SIZE, request.getBatchSize()));

        List<Card> queue = "new".equals(mode)
                ? buildNewQueue(userId, deckId)
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
        List<ReviewSyncItem> items = request.getItems() == null ? List.of() : request.getItems();
        List<ReviewSyncItemResult> results = new ArrayList<>(items.size());
        int synced = 0;
        int conflicts = 0;
        int missing = 0;

        // refresh_time 只取一次，避免循环内每条评分都点查 users 表
        LocalTime refreshTime = getRefreshTime(userId);
        LocalDate today = DateUtils.calculateToday(refreshTime);

        // 1) 幂等检查批量化：一次 IN 查询替代逐条查询
        List<String> requestIds = items.stream()
                .map(ReviewSyncItem::getClientRequestId)
                .filter(s -> s != null && !s.isBlank())
                .toList();
        Map<String, ReviewLog> existingById = requestIds.isEmpty() ? Map.of()
                : reviewLogRepository.findByUserIdAndClientRequestIdIn(userId, requestIds).stream()
                        .collect(Collectors.toMap(ReviewLog::getClientRequestId, l -> l, (a, b) -> a));

        Map<Integer, ReviewSyncItemResult> resultByIndex = new HashMap<>();
        List<Integer> pendingIndices = new ArrayList<>();
        for (int i = 0; i < items.size(); i++) {
            ReviewSyncItem item = items.get(i);
            String clientRequestId = item.getClientRequestId();
            ReviewLog existing = (clientRequestId == null || clientRequestId.isBlank())
                    ? null
                    : existingById.get(clientRequestId);
            if (existing == null) {
                pendingIndices.add(i);
                continue;
            }
            if (existing.getCardId().equals(item.getCardId()) && existing.getRating().equals(item.getRating())) {
                resultByIndex.put(i, new ReviewSyncItemResult(clientRequestId, "ALREADY_SYNCED", null));
            } else {
                resultByIndex.put(i, new ReviewSyncItemResult(clientRequestId, "CONFLICT", null));
                conflicts++;
            }
        }

        // 2) 需要落库的卡片一次批量加锁（SELECT ... FOR UPDATE），替代逐条加锁
        List<UUID> pendingCardIds = pendingIndices.stream()
                .map(items::get)
                .map(ReviewSyncItem::getCardId)
                .distinct()
                .toList();
        Map<UUID, Card> cardMap = pendingCardIds.isEmpty() ? Map.of()
                : cardRepository.findByIdInAndUserIdForUpdate(pendingCardIds, userId).stream()
                        .collect(Collectors.toMap(Card::getId, c -> c, (a, b) -> a));

        // 3) 内存中完成排期计算，最后批量落库
        List<Card> cardsToSave = new ArrayList<>();
        List<ReviewLog> logsToSave = new ArrayList<>();
        for (int idx : pendingIndices) {
            ReviewSyncItem item = items.get(idx);
            String clientRequestId = item.getClientRequestId();
            Card card = cardMap.get(item.getCardId());
            if (card == null) {
                resultByIndex.put(idx, new ReviewSyncItemResult(clientRequestId, "CARD_NOT_FOUND", null));
                missing++;
                continue;
            }
            if (card.getReviewVersion() != item.getReviewVersion()) {
                resultByIndex.put(idx,
                        new ReviewSyncItemResult(clientRequestId, "CONFLICT", toReviewCardResponse(card)));
                conflicts++;
                continue;
            }
            RatingOutcome outcome = computeRating(
                    userId, item.getCardId(), card, item.getRating(),
                    clientRequestId, DateUtils.toBusinessLocalDateTime(item.getRatedAt()),
                    refreshTime, today);
            cardsToSave.add(card);
            logsToSave.add(outcome.log());
            resultByIndex.put(idx, new ReviewSyncItemResult(clientRequestId, "SYNCED", null));
            synced++;
        }

        if (!cardsToSave.isEmpty()) {
            cardRepository.saveAll(cardsToSave);
        }
        if (!logsToSave.isEmpty()) {
            reviewLogRepository.saveAll(logsToSave);
        }

        // 4) 结果按请求顺序输出
        for (int i = 0; i < items.size(); i++) {
            results.add(resultByIndex.get(i));
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
                        null, false, 0, 0, current.getReviewVersion(),
                        current.getReentryStage(), current.getLearningOrigin());
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

        LocalTime refreshTime = getRefreshTime(userId);
        LocalDate today = DateUtils.calculateToday(refreshTime);
        return applyRating(userId, cardId, card, request.getRating(),
                clientRequestId, DateUtils.now(), refreshTime, today);
    }

    @Scheduled(fixedDelay = 3600000)
    @Transactional
    public void cleanupExpiredSessions() {
        reviewSessionRepository.deleteExpired(DateUtils.now());
    }

    private RateResponse applyRating(UUID userId, UUID cardId, Card card,
                                     String rating, String clientRequestId,
                                     LocalDateTime reviewedAt,
                                     LocalTime refreshTime, LocalDate today) {
        RatingOutcome outcome = computeRating(
                userId, cardId, card, rating, clientRequestId, reviewedAt, refreshTime, today);
        cardRepository.save(card);
        reviewLogRepository.save(outcome.log());
        return toRateResponse(cardId, rating, card, outcome.result(), today);
    }

    /**
     * 纯内存计算评分结果（不落库）：调用方决定如何批量保存。
     * 排期算法会就地修改 card 字段，同时返回需要写入的 ReviewLog。
     */
    private RatingOutcome computeRating(UUID userId, UUID cardId, Card card,
                                        String rating, String clientRequestId,
                                        LocalDateTime reviewedAt,
                                        LocalTime refreshTime, LocalDate today) {
        boolean wasNewCard = card.getStage() == 0 && !card.isLearningMode();
        // 评分时刻的学习来源快照（排程算法会就地修改卡片状态，必须先取值）：
        // 学新阶段产生的重学（NEW）评分不计入「今日复习」。
        String originAtRating = card.getLearningOrigin();
        int overdueDays = card.getNextReviewDate() == null
                ? 0
                : (int) Math.max(0, ChronoUnit.DAYS.between(card.getNextReviewDate(), today));
        SchedulingEngine.RatingResult result;
        switch (rating) {
            case "FORGET" -> result = schedulingEngine.rateForget(card, refreshTime);
            case "VAGUE" -> result = schedulingEngine.rateVague(card, refreshTime, overdueDays);
            case "FAMILIAR" -> result = schedulingEngine.rateFamiliar(card, refreshTime);
            default -> throw new BusinessException(400, "review.rating.invalid");
        }

        ReviewLog log = new ReviewLog();
        log.setCardId(cardId);
        log.setUserId(userId);
        log.setRating(rating);
        log.setStageBefore(result.getStageBefore());
        log.setStageAfter(result.getStageAfter());
        log.setNewCard(wasNewCard);
        log.setLearningOrigin(originAtRating);
        log.setClientRequestId(clientRequestId);
        log.setReviewedAt(reviewedAt == null ? DateUtils.now() : reviewedAt);

        return new RatingOutcome(log, result);
    }

    private RateResponse toRateResponse(UUID cardId, String rating, Card card,
                                        SchedulingEngine.RatingResult result, LocalDate today) {
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
                card.getReviewVersion(),
                card.getReentryStage(),
                card.getLearningOrigin());
    }

    private record RatingOutcome(ReviewLog log, SchedulingEngine.RatingResult result) {}

    private List<Card> buildDueQueue(UUID userId, UUID deckId) {
        LocalTime refreshTime = getRefreshTime(userId);
        LocalDate today = DateUtils.calculateToday(refreshTime);
        List<Card> dueCards = cardRepository.findDueCards(userId, today, deckId);
        List<Card> learningCards = cardRepository.findLearningModeCardsForReview(userId, today, deckId);
        return interleaveLearningCards(dueCards, learningCards);
    }

    /**
     * 学新队列 = 待学新卡 + 学新阶段产生的重学卡（来源 NEW），
     * 重学卡按 2^n 间距插入。退出重进学新页仍能继续刷到忘记/模糊的卡。
     */
    private List<Card> buildNewQueue(UUID userId, UUID deckId) {
        LocalTime refreshTime = getRefreshTime(userId);
        LocalDate today = DateUtils.calculateToday(refreshTime);
        List<Card> newCards = cardRepository.findNewCards(userId, deckId);
        List<Card> learningNew = cardRepository.findLearningModeCardsForNew(userId, today, deckId);
        return interleaveLearningCards(newCards, learningNew);
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
                card.getReviewVersion(),
                card.getLearningOrigin());
    }

    private LocalTime getRefreshTime(UUID userId) {
        return userRepository.findById(userId)
                .map(User::getRefreshTime)
                .orElse(LocalTime.of(4, 0));
    }
}