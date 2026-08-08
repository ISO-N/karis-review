package top.kariscode.karisreview.review.service;

import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import top.kariscode.karisreview.auth.repository.UserRepository;
import top.kariscode.karisreview.auth.util.UserRefreshTime;
import top.kariscode.karisreview.card.entity.Card;
import top.kariscode.karisreview.card.entity.SchedulingState;
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
import java.util.HashMap;
import java.util.List;
import java.util.Map;
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
        LocalTime refreshTime = UserRefreshTime.resolve(userRepository, userId);
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
            // 幂等判定共享 checkIdempotency（架构评审 B1：与 rateCard 单一实现）
            switch (checkIdempotency(existing, item.getCardId(), item.getRating())) {
                case REPLAY ->
                        resultByIndex.put(i, new ReviewSyncItemResult(clientRequestId, "ALREADY_SYNCED", null));
                case CONFLICT -> {
                    resultByIndex.put(i, new ReviewSyncItemResult(clientRequestId, "CONFLICT", null));
                    conflicts++;
                }
                default -> throw new IllegalStateException("existing 非空时不可能 NEW");
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

        // 3) 内存中完成排期计算（共享评分管道 rateSingle），最后批量落库
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
            // 共享评分管道（架构评审 B1）：版本冲突判定 + computeRating 单一实现，
            // 幂等已在第一循环预筛（此处 existing 恒 null）。
            RatingOutcome outcome = rateSingle(
                    userId, card, item.getRating(), clientRequestId, null,
                    item.getReviewVersion(),
                    DateUtils.toBusinessLocalDateTime(item.getRatedAt()), refreshTime, today);
            if (outcome.conflict) {
                resultByIndex.put(idx, new ReviewSyncItemResult(
                        clientRequestId, "CONFLICT", toReviewCardResponse(outcome.conflictCard)));
                conflicts++;
                continue;
            }
            cardsToSave.add(card);
            logsToSave.add(outcome.log);
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
        ReviewLog existing = null;
        if (clientRequestId != null && !clientRequestId.isBlank()) {
            existing = reviewLogRepository
                    .findByUserIdAndClientRequestId(userId, clientRequestId)
                    .orElse(null);
        }
        if (existing != null) {
            // 幂等判定共享 checkIdempotency（架构评审 B1）：两种情况都不锁卡——
            // 重放直接返回历史（卡可能已被删除，如撤销导入后重放评分）；
            // 同一 clientRequestId 不同内容视为冲突直接 409，不查卡（保持历史行为）。
            if (checkIdempotency(existing, cardId, request.getRating()) == Idempotency.REPLAY) {
                Card current = cardRepository.findByIdAndUserId(cardId, userId).orElse(null);
                return new RateResponse(
                        cardId, existing.getRating(), existing.getStageBefore(), existing.getStageAfter(),
                        null, false, 0, 0,
                        current != null ? current.getReviewVersion() : 0,
                        current != null ? current.getReentryStage() : null,
                        current != null ? current.getLearningOrigin() : null);
            }
            userLogService.log(userId, "WARN", "REVIEW", String.format(
                    "Rating conflict: card=%s, clientRequestId=%s, expected=%s/%s, got=%s/%s",
                    cardId, clientRequestId,
                    existing.getCardId(), existing.getRating(),
                    cardId, request.getRating()));
            throw new BusinessException(409, "review.conflict.request");
        }

        Card card = cardRepository.findByIdAndUserIdForUpdate(cardId, userId)
                .orElseThrow(() -> new BusinessException(404, "review.card.notfound"));

        LocalTime refreshTime = UserRefreshTime.resolve(userRepository, userId);
        LocalDate today = DateUtils.calculateToday(refreshTime);

        // 共享评分管道（架构评审 B1）：幂等判定 + 版本冲突判定 + 排期计算单一实现，
        // 与 syncRatings 同一管道、不同出口。
        RatingOutcome outcome = rateSingle(
                userId, card, request.getRating(), clientRequestId, null,
                request.getReviewVersion() == null ? null : request.getReviewVersion().longValue(),
                DateUtils.now(), refreshTime, today);
        if (outcome.conflict) {
            userLogService.log(userId, "WARN", "REVIEW", String.format(
                    "Version conflict: card=%s, expected=%d, got=%d",
                    cardId, card.getReviewVersion(), request.getReviewVersion()));
            throw new BusinessException(409, "review.conflict.version");
        }

        cardRepository.save(card);
        reviewLogRepository.save(outcome.log);
        return toRateResponse(cardId, request.getRating(), card, outcome.result, today);
    }

    @Scheduled(fixedDelay = 3600000)
    @Transactional
    public void cleanupExpiredSessions() {
        reviewSessionRepository.deleteExpired(DateUtils.now());
    }

    /**
     * 单卡评分共享管道（架构评审 B1）：幂等判定 → 版本冲突判定 → computeRating。
     *
     * 返回统一结果（不落库），rateCard 与 syncRatings 各自按出口语义处理：
     * 幂等重放 / 冲突（可携带当前卡用于响应） / 成功（log + result）。
     * 幂等判定与版本判定单一实现（checkIdempotency / isVersionConflict）。
     */
    private RatingOutcome rateSingle(UUID userId, Card card, String rating,
                                     String clientRequestId, ReviewLog existing,
                                     Long expectedVersion,
                                     LocalDateTime reviewedAt,
                                     LocalTime refreshTime, LocalDate today) {
        if (existing != null) {
            return switch (checkIdempotency(existing, card.getId(), rating)) {
                case REPLAY -> RatingOutcome.replayed();
                case CONFLICT -> RatingOutcome.conflict(null);
                default -> throw new IllegalStateException("existing 非空时不可能 NEW");
            };
        }
        if (isVersionConflict(expectedVersion, card)) {
            return RatingOutcome.conflict(card);
        }
        return computeRating(userId, card.getId(), card, rating,
                clientRequestId, reviewedAt, refreshTime, today);
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

        return new RatingOutcome(log, result, false, false, null);
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

    /** 评分管道输出：成功（log+result）/ 幂等重放 / 冲突（可携带当前卡）。 */
    private static final class RatingOutcome {
        final ReviewLog log;
        final SchedulingEngine.RatingResult result;
        final boolean replayed;
        final boolean conflict;
        final Card conflictCard;

        RatingOutcome(ReviewLog log, SchedulingEngine.RatingResult result,
                      boolean replayed, boolean conflict, Card conflictCard) {
            this.log = log;
            this.result = result;
            this.replayed = replayed;
            this.conflict = conflict;
            this.conflictCard = conflictCard;
        }

        static RatingOutcome replayed() {
            return new RatingOutcome(null, null, true, false, null);
        }

        static RatingOutcome conflict(Card conflictCard) {
            return new RatingOutcome(null, null, false, true, conflictCard);
        }
    }

    /** 幂等判定结果：重放（请求与历史一致）/ 冲突 / 无历史需评分。 */
    private enum Idempotency { REPLAY, CONFLICT, NEW }

    /** 幂等判定单一实现（架构评审 B1）：rateCard 与 syncRatings 共用。 */
    private static Idempotency checkIdempotency(ReviewLog existing, UUID cardId, String rating) {
        if (existing == null) {
            return Idempotency.NEW;
        }
        return (existing.getCardId().equals(cardId) && existing.getRating().equals(rating))
                ? Idempotency.REPLAY
                : Idempotency.CONFLICT;
    }

    /** 乐观锁版本冲突判定单一实现（架构评审 B1）：期望版本为空时不检查。 */
    private static boolean isVersionConflict(Long expectedVersion, Card card) {
        return expectedVersion != null && expectedVersion != card.getReviewVersion();
    }

    private List<Card> buildDueQueue(UUID userId, UUID deckId) {
        LocalTime refreshTime = UserRefreshTime.resolve(userRepository, userId);
        LocalDate today = DateUtils.calculateToday(refreshTime);
        List<Card> dueCards = cardRepository.findDueCards(userId, today, deckId);
        List<Card> learningCards = cardRepository.findLearningModeCardsForReview(userId, today, deckId);
        return QueueInterleaver.interleave(dueCards, learningCards);
    }

    /**
     * 学新队列 = 待学新卡 + 学新阶段产生的重学卡（来源 NEW），
     * 重学卡按 2^n 间距插入（QueueInterleaver，架构评审 B1）。
     * 退出重进学新页仍能继续刷到忘记/模糊的卡。
     */
    private List<Card> buildNewQueue(UUID userId, UUID deckId) {
        LocalTime refreshTime = UserRefreshTime.resolve(userRepository, userId);
        LocalDate today = DateUtils.calculateToday(refreshTime);
        List<Card> newCards = cardRepository.findNewCards(userId, deckId);
        List<Card> learningNew = cardRepository.findLearningModeCardsForNew(userId, today, deckId);
        return QueueInterleaver.interleave(newCards, learningNew);
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
        SchedulingState s = card.getSchedulingState();
        return new ReviewCardResponse(
                card.getId(), card.getDeckId(),
                card.getFront(), card.getBack(),
                s.getStage(), s.isLearningMode(),
                s.getConsecutiveFamiliar(),
                s.getReentryStage(),
                s.getNextReviewDate(),
                s.getLearningStep(),
                card.getReviewVersion(),
                s.getLearningOrigin());
    }
}