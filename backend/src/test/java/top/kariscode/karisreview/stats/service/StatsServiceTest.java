package top.kariscode.karisreview.stats.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import top.kariscode.karisreview.auth.entity.User;
import top.kariscode.karisreview.auth.repository.UserRepository;
import top.kariscode.karisreview.card.repository.CardRepository;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.common.util.DateUtils;
import top.kariscode.karisreview.deck.entity.Deck;
import top.kariscode.karisreview.deck.repository.DeckRepository;
import top.kariscode.karisreview.review.repository.ReviewLogRepository;
import top.kariscode.karisreview.stats.dto.DeckStatsResponse;
import top.kariscode.karisreview.stats.dto.OverviewStatsResponse;
import top.kariscode.karisreview.stats.dto.TrendStatsResponse;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class StatsServiceTest {

    @Mock
    private CardRepository cardRepository;

    @Mock
    private DeckRepository deckRepository;

    @Mock
    private ReviewLogRepository reviewLogRepository;

    @Mock
    private UserRepository userRepository;

    private StatsService service;

    @BeforeEach
    void setUp() {
        service = new StatsService(
                cardRepository, deckRepository, reviewLogRepository, userRepository);
    }

    @Test
    void getOverviewBuildsCountsAndDistributions() {
        UUID userId = UUID.randomUUID();
        LocalTime refreshTime = LocalTime.of(4, 0);
        LocalDate today = DateUtils.calculateToday(refreshTime);
        when(userRepository.findById(userId)).thenReturn(Optional.of(user()));
        when(deckRepository.countByUserId(userId)).thenReturn(2L);
        when(reviewLogRepository.countReviewedToday(
                userId, today.atTime(refreshTime), today.plusDays(1).atTime(refreshTime)))
                .thenReturn(4L);
        when(reviewLogRepository.countLearnedToday(
                userId, today.atTime(refreshTime), today.plusDays(1).atTime(refreshTime)))
                .thenReturn(1L);
        // 聚合列: stage, total, learning_cards(stage<5), mastered(stage>=5 非学习),
        //         new_cards(stage=0 非学习), due(next_review_date<=today)
        when(cardRepository.aggregateOverviewStats(userId, today)).thenReturn(
                List.<Object[]>of(
                        new Object[]{3, 5L, 5L, 0L, 0L, 1L},
                        new Object[]{5, 2L, 0L, 2L, 0L, 2L}));

        OverviewStatsResponse stats = service.getOverview(userId);

        assertEquals(7, stats.getTotalCards());
        assertEquals(2, stats.getTotalDecks());
        assertEquals(3, stats.getDueToday());
        assertEquals(4, stats.getReviewedToday());
        assertEquals(1, stats.getLearnedToday());
        assertEquals(2, stats.getMasteredCards());
        assertEquals(0, stats.getNewCards());
        assertEquals(5, stats.getLearningCards());
        assertEquals(5L, stats.getStageDistribution().get(3));
        assertEquals(2L, stats.getStageDistribution().get(5));
        assertEquals(1L, stats.getDueStageDistribution().get(3));
    }

    @Test
    void getDeckStatsBuildsDeckCounters() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        Deck deck = new Deck();
        deck.setId(deckId);
        deck.setUserId(userId);
        deck.setName("日语");
        LocalTime refreshTime = LocalTime.of(4, 0);
        LocalDate today = DateUtils.calculateToday(refreshTime);
        when(deckRepository.findByIdAndUserId(deckId, userId)).thenReturn(Optional.of(deck));
        when(userRepository.findById(userId)).thenReturn(Optional.of(user()));
        when(cardRepository.countByDeckId(deckId)).thenReturn(5L);
        when(cardRepository.countDueByDeckId(deckId, today)).thenReturn(2);
        when(reviewLogRepository.countReviewedTodayForDeck(
                userId, deckId, today.atTime(refreshTime), today.plusDays(1).atTime(refreshTime)))
                .thenReturn(3L);
        when(cardRepository.countNewByDeckId(deckId)).thenReturn(1L);
        when(cardRepository.countByDeckIdAndLearningModeTrue(deckId)).thenReturn(2L);
        when(cardRepository.countByDeckIdAndStageGreaterThanEqual(deckId, 5)).thenReturn(1L);
        when(cardRepository.countByStageGroupedByDeck(deckId)).thenReturn(
                List.<Object[]>of(new Object[]{0, 1L}));
        when(cardRepository.countDueByStageGroupedByDeck(deckId, today)).thenReturn(
                List.<Object[]>of(new Object[]{2, 2L}));

        DeckStatsResponse stats = service.getDeckStats(userId, deckId);

        assertEquals(deckId.toString(), stats.getDeckId());
        assertEquals("日语", stats.getDeckName());
        assertEquals(5, stats.getTotalCards());
        assertEquals(2, stats.getDueToday());
        assertEquals(3, stats.getReviewedToday());
        assertEquals(1, stats.getNewCards());
        assertEquals(2, stats.getLearningCards());
        assertEquals(1, stats.getMasteredCards());
        assertEquals(1L, stats.getStageDistribution().get(0));
        assertEquals(2L, stats.getDueStageDistribution().get(2));
    }

    @Test
    void getDeckStatsRejectsDeckNotOwned() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        when(deckRepository.findByIdAndUserId(deckId, userId)).thenReturn(Optional.empty());

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.getDeckStats(userId, deckId));

        assertEquals(404, exception.getCode());
    }

    @Test
    void getTrendFillsMissingDaysWithZerosAndMergesRows() {
        UUID userId = UUID.randomUUID();
        LocalTime refreshTime = LocalTime.of(4, 0);
        LocalDate today = DateUtils.calculateToday(refreshTime);
        LocalDateTime start = today.minusDays(5).atTime(refreshTime);
        // 聚合行: [业务日, 复习次数(非新卡), 新学次数(新卡且 FAMILIAR)]
        LocalDate logDay = today.minusDays(2);
        when(userRepository.findById(userId)).thenReturn(Optional.of(user()));
        when(reviewLogRepository.findDailyTrend(userId, start, refreshTime))
                .thenReturn(List.<Object[]>of(
                        new Object[]{java.sql.Date.valueOf(logDay), 3L, 1L}));

        List<TrendStatsResponse> trend = service.getTrend(userId, 5);

        assertEquals(5, trend.size());
        assertEquals(3, trend.get(2).getReviewed());
        assertEquals(1, trend.get(2).getLearned());
        assertEquals(0, trend.get(0).getReviewed());
        assertEquals(today, trend.get(4).getDate());
    }

    @Test
    void getOverviewUsesDefaultRefreshTimeWhenUserMissing() {
        UUID userId = UUID.randomUUID();
        LocalTime refreshTime = LocalTime.of(4, 0);
        LocalDate today = DateUtils.calculateToday(refreshTime);
        when(userRepository.findById(userId)).thenReturn(Optional.empty());
        when(deckRepository.countByUserId(userId)).thenReturn(0L);
        when(reviewLogRepository.countReviewedToday(
                userId, today.atTime(refreshTime), today.plusDays(1).atTime(refreshTime)))
                .thenReturn(0L);
        when(reviewLogRepository.countLearnedToday(
                userId, today.atTime(refreshTime), today.plusDays(1).atTime(refreshTime)))
                .thenReturn(0L);
        when(cardRepository.aggregateOverviewStats(userId, today)).thenReturn(List.of());

        OverviewStatsResponse stats = service.getOverview(userId);

        assertEquals(0, stats.getTotalCards());
    }

    private User user() {
        return new User();
    }
}
