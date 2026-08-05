package top.kariscode.karisreview.stats.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import top.kariscode.karisreview.auth.api.IdentityPort;
import top.kariscode.karisreview.card.repository.CardRepository;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.common.util.DateUtils;
import top.kariscode.karisreview.deck.entity.Deck;
import top.kariscode.karisreview.deck.repository.DeckRepository;
import top.kariscode.karisreview.review.entity.ReviewLog;
import top.kariscode.karisreview.review.repository.ReviewLogRepository;
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
import java.util.Optional;
import java.util.UUID;

@Service
public class StatsService {

    private final CardRepository cardRepository;
    private final DeckRepository deckRepository;
    private final ReviewLogRepository reviewLogRepository;
    private final IdentityPort identityPort;
    private final Optional<DailyReviewStatsService> dailyStatsService;

    public StatsService(CardRepository cardRepository,
                        DeckRepository deckRepository,
                        ReviewLogRepository reviewLogRepository,
                        IdentityPort identityPort) {
        this(cardRepository, deckRepository, reviewLogRepository, identityPort, Optional.empty());
    }

    @Autowired
    public StatsService(CardRepository cardRepository,
                        DeckRepository deckRepository,
                        ReviewLogRepository reviewLogRepository,
                        IdentityPort identityPort,
                        Optional<DailyReviewStatsService> dailyStatsService) {
        this.cardRepository = cardRepository;
        this.deckRepository = deckRepository;
        this.reviewLogRepository = reviewLogRepository;
        this.identityPort = identityPort;
        this.dailyStatsService = dailyStatsService;
    }

    public OverviewStatsResponse getOverview(UUID userId) {
        LocalTime refreshTime = getRefreshTime(userId);
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

        // 预聚合优先：今日 reviewed/learned 读 daily_review_stats（避免实时扫描 review_logs）；
        // 预聚合数据缺失（如刚部署未触发重算）时回退实时查询，保证口径一致。
        Optional<int[]> todayCounts = dailyStatsService.flatMap(s -> s.getTodayCounts(userId, refreshTime));
        if (todayCounts.isPresent()) {
            stats.setReviewedToday(todayCounts.get()[0]);
            stats.setLearnedToday(todayCounts.get()[1]);
        } else {
            stats.setReviewedToday(reviewLogRepository.countReviewedToday(userId, refreshStart, refreshEnd));
            stats.setLearnedToday(reviewLogRepository.countLearnedToday(userId, refreshStart, refreshEnd));
        }
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

        LocalTime refreshTime = getRefreshTime(userId);
        LocalDate today = DateUtils.calculateToday(refreshTime);
        LocalDateTime refreshStart = today.atTime(refreshTime);
        LocalDateTime refreshEnd = today.plusDays(1).atTime(refreshTime);

        DeckStatsResponse stats = new DeckStatsResponse();
        stats.setDeckId(deckId.toString());
        stats.setDeckName(deck.getName());
        stats.setTotalCards(cardRepository.countByDeckId(deckId));
        stats.setDueToday(cardRepository.countDueByDeckId(deckId, today));
        stats.setReviewedToday(reviewLogRepository.countReviewedTodayForDeck(userId, deckId, refreshStart, refreshEnd));
        stats.setNewCards(cardRepository.countByDeckIdAndStageAndLearningModeFalse(deckId, 0));
        stats.setLearningCards(cardRepository.countByDeckIdAndLearningModeTrue(deckId));
        stats.setMasteredCards(cardRepository.countByDeckIdAndStageGreaterThanEqual(deckId, 5));
        stats.setStageDistribution(distributionFromRows(
                cardRepository.countByStageGroupedByDeck(deckId)));
        stats.setDueStageDistribution(distributionFromRows(
                cardRepository.countDueByStageGroupedByDeck(deckId, today)));
        return stats;
    }

    public List<TrendStatsResponse> getTrend(UUID userId, int days) {
        LocalTime refreshTime = getRefreshTime(userId);

        // 预聚合优先：趋势读 daily_review_stats（与 review_logs 数据量解耦，ADR-007）。
        // 预聚合数据缺失时回退实时查询，保证首次部署/测试环境行为一致。
        if (dailyStatsService.isPresent()) {
            List<TrendStatsResponse> preAgg = dailyStatsService.get().getTrend(userId, refreshTime, days);
            if (!preAgg.isEmpty()) {
                return preAgg;
            }
        }

        LocalDate today = DateUtils.calculateToday(refreshTime);
        LocalDateTime start = today.minusDays(days).atTime(refreshTime);

        List<ReviewLog> logs = reviewLogRepository.findByUserIdAndReviewedAtAfter(userId, start);
        Map<LocalDate, TrendStatsResponse> trendMap = new LinkedHashMap<>();

        for (int i = days - 1; i >= 0; i--) {
            LocalDate date = today.minusDays(i);
            trendMap.put(date, new TrendStatsResponse(date, 0, 0));
        }

        for (ReviewLog log : logs) {
            LocalDate date = DateUtils.calculateToday(refreshTime, log.getReviewedAt());
            TrendStatsResponse existing = trendMap.get(date);
            if (existing != null) {
                if (log.isNewCard()) {
                    if ("FAMILIAR".equals(log.getRating())) {
                        existing.setLearned(existing.getLearned() + 1);
                    }
                } else {
                    existing.setReviewed(existing.getReviewed() + 1);
                }
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

    private LocalTime getRefreshTime(UUID userId) {
        return identityPort.refreshTimeOf(userId);
    }
}
