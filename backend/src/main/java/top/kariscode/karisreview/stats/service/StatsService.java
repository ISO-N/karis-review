package top.kariscode.karisreview.stats.service;

import org.springframework.stereotype.Service;
import top.kariscode.karisreview.auth.entity.User;
import top.kariscode.karisreview.auth.repository.UserRepository;
import top.kariscode.karisreview.auth.util.UserRefreshTime;
import top.kariscode.karisreview.card.repository.CardRepository;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.common.util.DateUtils;
import top.kariscode.karisreview.deck.entity.Deck;
import top.kariscode.karisreview.deck.repository.DeckRepository;
import top.kariscode.karisreview.review.repository.ReviewLogRepository;
import top.kariscode.karisreview.stats.dto.DeckCounters;
import top.kariscode.karisreview.stats.dto.DeckStatsResponse;
import top.kariscode.karisreview.stats.dto.OverviewStatsResponse;
import top.kariscode.karisreview.stats.dto.TrendStatsResponse;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class StatsService {

    private final CardRepository cardRepository;
    private final DeckRepository deckRepository;
    private final ReviewLogRepository reviewLogRepository;
    private final UserRepository userRepository;

    public StatsService(CardRepository cardRepository,
                        DeckRepository deckRepository,
                        ReviewLogRepository reviewLogRepository,
                        UserRepository userRepository) {
        this.cardRepository = cardRepository;
        this.deckRepository = deckRepository;
        this.reviewLogRepository = reviewLogRepository;
        this.userRepository = userRepository;
    }

    /**
     * 卡组计数唯一出口（架构评审候选 4）：DeckService.toDeckResponse 与
     * getDeckStats 共用。due/new 口径见 CardQueryPredicates。
     */
    public DeckCounters getDeckCounters(UUID userId, UUID deckId) {
        LocalTime refreshTime = UserRefreshTime.resolve(userRepository, userId);
        LocalDate today = DateUtils.calculateToday(refreshTime);

        DeckCounters counters = new DeckCounters();
        counters.setCardCount((int) cardRepository.countByDeckId(deckId));
        counters.setDueCount(cardRepository.countDueByDeckId(deckId, today));
        counters.setNewCount((int) cardRepository.countNewByDeckId(deckId));
        counters.setMasteredCount((int) cardRepository.countByDeckIdAndStageGreaterThanEqual(deckId, 5));
        counters.setStageDistribution(distributionFromRows(
                cardRepository.countByStageGroupedByDeck(deckId)));
        counters.setDueStageDistribution(distributionFromRows(
                cardRepository.countDueByStageGroupedByDeck(deckId, today)));
        return counters;
    }

    public OverviewStatsResponse getOverview(UUID userId) {
        LocalTime refreshTime = UserRefreshTime.resolve(userRepository, userId);
        LocalDate today = DateUtils.calculateToday(refreshTime);

        LocalDateTime refreshStart = today.atTime(refreshTime);
        LocalDateTime refreshEnd = today.plusDays(1).atTime(refreshTime);

        OverviewStatsResponse stats = new OverviewStatsResponse();

        // 一次聚合查询产出：总量、各 stage 分布、due 分布、学习卡、熟练卡、新卡
        // （替代原来的 7+ 条独立 COUNT，配合 (user_id, stage, learning_mode) 索引走 Index Only Scan）
        long totalCards = 0;
        long dueToday = 0;
        long masteredCards = 0;
        long newCards = 0;
        long learningCards = 0;
        List<Long> stageDistribution = new ArrayList<>(List.of(0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L));
        List<Long> dueStageDistribution = new ArrayList<>(List.of(0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L));
        for (Object[] row : cardRepository.aggregateOverviewStats(userId, today)) {
            int stage = ((Number) row[0]).intValue();
            long total = ((Number) row[1]).longValue();
            long learning = ((Number) row[2]).longValue();
            long mastered = ((Number) row[3]).longValue();
            long fresh = ((Number) row[4]).longValue();
            long due = ((Number) row[5]).longValue();
            totalCards += total;
            dueToday += due;
            masteredCards += mastered;
            newCards += fresh;
            learningCards += learning;
            if (stage >= 0 && stage <= 8) {
                stageDistribution.set(stage, stageDistribution.get(stage) + total);
                dueStageDistribution.set(stage, dueStageDistribution.get(stage) + due);
            }
        }

        stats.setTotalCards(totalCards);
        stats.setTotalDecks(deckRepository.countByUserId(userId));
        stats.setDueToday(dueToday);
        stats.setReviewedToday(reviewLogRepository.countReviewedToday(userId, refreshStart, refreshEnd));
        stats.setLearnedToday(reviewLogRepository.countLearnedToday(userId, refreshStart, refreshEnd));
        stats.setMasteredCards(masteredCards);
        stats.setNewCards(newCards);
        stats.setLearningCards(learningCards);
        stats.setStageDistribution(stageDistribution);
        stats.setDueStageDistribution(dueStageDistribution);
        return stats;
    }

    public DeckStatsResponse getDeckStats(UUID userId, UUID deckId) {
        Deck deck = deckRepository.findByIdAndUserId(deckId, userId)
                .orElseThrow(() -> new BusinessException(404, "stats.deck.notfound"));

        LocalTime refreshTime = UserRefreshTime.resolve(userRepository, userId);
        LocalDate today = DateUtils.calculateToday(refreshTime);
        LocalDateTime refreshStart = today.atTime(refreshTime);
        LocalDateTime refreshEnd = today.plusDays(1).atTime(refreshTime);

        DeckStatsResponse stats = new DeckStatsResponse();
        stats.setDeckId(deckId.toString());
        stats.setDeckName(deck.getName());
        stats.setTotalCards(cardRepository.countByDeckId(deckId));
        stats.setDueToday(cardRepository.countDueByDeckId(deckId, today));
        stats.setReviewedToday(reviewLogRepository.countReviewedTodayForDeck(userId, deckId, refreshStart, refreshEnd));
        stats.setNewCards(cardRepository.countNewByDeckId(deckId));
        stats.setLearningCards(cardRepository.countByDeckIdAndLearningModeTrue(deckId));
        stats.setMasteredCards(cardRepository.countByDeckIdAndStageGreaterThanEqual(deckId, 5));
        stats.setStageDistribution(distributionFromRows(
                cardRepository.countByStageGroupedByDeck(deckId)));
        stats.setDueStageDistribution(distributionFromRows(
                cardRepository.countDueByStageGroupedByDeck(deckId, today)));
        return stats;
    }

    public List<TrendStatsResponse> getTrend(UUID userId, int days) {
        LocalTime refreshTime = UserRefreshTime.resolve(userRepository, userId);
        LocalDate today = DateUtils.calculateToday(refreshTime);
        LocalDateTime start = today.minusDays(days).atTime(refreshTime);

        Map<LocalDate, TrendStatsResponse> trendMap = new LinkedHashMap<>();
        for (int i = days - 1; i >= 0; i--) {
            LocalDate date = today.minusDays(i);
            trendMap.put(date, new TrendStatsResponse(date, 0, 0));
        }

        // 数据库内按业务日聚合，仅返回非零日期行（最多 days 行），
        // 替代原先把 30 天全量 ReviewLog 实体加载进 JVM 逐条累计的写法。
        for (Object[] row : reviewLogRepository.findDailyTrend(userId, start, refreshTime)) {
            LocalDate date = ((java.sql.Date) row[0]).toLocalDate();
            long reviewed = ((Number) row[1]).longValue();
            long learned = ((Number) row[2]).longValue();
            TrendStatsResponse existing = trendMap.get(date);
            if (existing != null) {
                existing.setReviewed(existing.getReviewed() + reviewed);
                existing.setLearned(existing.getLearned() + learned);
            }
        }

        return new ArrayList<>(trendMap.values());
    }

    private List<Long> distributionFromRows(List<Object[]> rows) {
        List<Long> distribution = new ArrayList<>(List.of(0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L));
        for (Object[] row : rows) {
            int stage = ((Number) row[0]).intValue();
            if (stage >= 0 && stage <= 8) {
                distribution.set(stage, distribution.get(stage) + ((Number) row[1]).longValue());
            }
        }
        return distribution;
    }
}
