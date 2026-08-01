package top.kariscode.karisreview.stats.service;

import org.springframework.stereotype.Service;
import top.kariscode.karisreview.card.repository.CardRepository;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.common.util.DateUtils;
import top.kariscode.karisreview.deck.entity.Deck;
import top.kariscode.karisreview.deck.repository.DeckRepository;
import top.kariscode.karisreview.review.repository.ReviewLogRepository;
import top.kariscode.karisreview.stats.dto.DeckStatsResponse;
import top.kariscode.karisreview.stats.dto.OverviewStatsResponse;
import top.kariscode.karisreview.stats.dto.TrendStatsResponse;
import top.kariscode.karisreview.auth.entity.User;
import top.kariscode.karisreview.auth.repository.UserRepository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.*;
import java.util.stream.Collectors;

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

        // Calculate the refresh boundary times
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
                - cardRepository.countByUserIdAndStageLessThan(userId, 0)); // Should be 0
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

        // Stage distribution
        Map<String, Long> distribution = new HashMap<>();
        for (int i = 0; i <= 8; i++) {
            distribution.put(String.valueOf(i), 0L);
        }
        // We need to query actual stage distribution
        // This could be done with a custom query, but for now we'll use a simpler approach
        List<top.kariscode.karisreview.card.entity.Card> cards = cardRepository.findByDeckIdOrderByCreatedAtAsc(deckId);
        for (var card : cards) {
            String stageKey = String.valueOf(card.getStage());
            distribution.merge(stageKey, 1L, Long::sum);
        }
        stats.setStageDistribution(distribution);
        return stats;
    }

    public List<TrendStatsResponse> getTrend(UUID userId, int days) {
        LocalTime refreshTime = getRefreshTime(userId);
        LocalDate today = DateUtils.calculateToday(refreshTime);
        LocalDateTime start = today.minusDays(days).atTime(refreshTime);

        List<Object[]> rows = reviewLogRepository.findDailyTrend(userId, start);
        Map<LocalDate, TrendStatsResponse> trendMap = new LinkedHashMap<>();

        // Fill in all days with zeros
        for (int i = days - 1; i >= 0; i--) {
            LocalDate date = today.minusDays(i);
            trendMap.put(date, new TrendStatsResponse(date, 0, 0));
        }

        // Fill in actual data
        for (Object[] row : rows) {
            LocalDate date = row[0] instanceof java.sql.Date
                    ? ((java.sql.Date) row[0]).toLocalDate()
                    : (LocalDate) row[0];
            long reviewed = ((Number) row[1]).longValue();
            long learned = ((Number) row[2]).longValue();
            TrendStatsResponse existing = trendMap.get(date);
            if (existing != null) {
                existing.setReviewed(reviewed);
                existing.setLearned(learned);
            }
        }

        return new ArrayList<>(trendMap.values());
    }
    private LocalTime getRefreshTime(UUID userId) {
        return userRepository.findById(userId)
                .map(User::getRefreshTime)
                .orElse(LocalTime.of(4, 0));
    }
}