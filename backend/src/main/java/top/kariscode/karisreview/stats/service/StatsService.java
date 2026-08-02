package top.kariscode.karisreview.stats.service;

import org.springframework.stereotype.Service;
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
import top.kariscode.karisreview.auth.entity.User;
import top.kariscode.karisreview.auth.repository.UserRepository;

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

    public OverviewStatsResponse getOverview(UUID userId) {
        LocalTime refreshTime = getRefreshTime(userId);
        LocalDate today = DateUtils.calculateToday(refreshTime);

        LocalDateTime refreshStart = today.atTime(refreshTime);
        LocalDateTime refreshEnd = today.plusDays(1).atTime(refreshTime);

        OverviewStatsResponse stats = new OverviewStatsResponse();
        stats.setTotalCards(cardRepository.countByUserId(userId));
        stats.setTotalDecks(deckRepository.countByUserId(userId));
        stats.setDueToday(cardRepository.countDueToday(userId, today));
        stats.setReviewedToday(reviewLogRepository.countReviewedToday(userId, refreshStart, refreshEnd));
        stats.setLearnedToday(reviewLogRepository.countLearnedToday(userId, refreshStart, refreshEnd));
        stats.setMasteredCards(cardRepository.countByUserIdAndStageGreaterThanEqual(userId, 5));
        stats.setLearningCards(cardRepository.countByUserIdAndStageLessThan(userId, 5)
                - cardRepository.countByUserIdAndStageLessThan(userId, 0));
        stats.setStageDistribution(distributionFromRows(cardRepository.countByStageGrouped(userId)));
        stats.setDueStageDistribution(distributionFromRows(
                cardRepository.countDueByStageGrouped(userId, today)));
        return stats;
    }

    public DeckStatsResponse getDeckStats(UUID userId, UUID deckId) {
        Deck deck = deckRepository.findByIdAndUserId(deckId, userId)
                .orElseThrow(() -> new BusinessException(404, "牌组不存在"));

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
                existing.setReviewed(existing.getReviewed() + 1);
                if ("FAMILIAR".equals(log.getRating()) && log.getStageBefore() == 0) {
                    existing.setLearned(existing.getLearned() + 1);
                }
            }
        }

        return new ArrayList<>(trendMap.values());
    }

    private Map<String, Long> distributionFromRows(List<Object[]> rows) {
        Map<String, Long> distribution = new LinkedHashMap<>();
        for (int i = 0; i <= 8; i++) {
            distribution.put(String.valueOf(i), 0L);
        }
        for (Object[] row : rows) {
            String stage = String.valueOf(((Number) row[0]).intValue());
            distribution.merge(stage, ((Number) row[1]).longValue(), Long::sum);
        }
        return distribution;
    }

    private LocalTime getRefreshTime(UUID userId) {
        return userRepository.findById(userId)
                .map(User::getRefreshTime)
                .orElse(LocalTime.of(4, 0));
    }
}
