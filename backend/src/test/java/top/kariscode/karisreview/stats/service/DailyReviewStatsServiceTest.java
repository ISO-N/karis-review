package top.kariscode.karisreview.stats.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import top.kariscode.karisreview.auth.api.IdentityPort;
import top.kariscode.karisreview.stats.entity.DailyReviewStats;
import top.kariscode.karisreview.stats.repository.DailyReviewStatsRepository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DailyReviewStatsServiceTest {

    @Mock
    private DailyReviewStatsRepository statsRepository;

    @Mock
    private IdentityPort identityPort;

    private DailyReviewStatsService service;

    @BeforeEach
    void setUp() {
        service = new DailyReviewStatsService(statsRepository, identityPort);
        org.mockito.Mockito.lenient()
                .when(identityPort.refreshTimeOf(org.mockito.ArgumentMatchers.any()))
                .thenReturn(LocalTime.of(4, 0));
    }

    @Test
    void incrementFromEventUpdatesDeckAndAllRows() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();

        service.incrementFromEvent(userId, deckId, LocalDateTime.now(), false, "FAMILIAR");

        verify(statsRepository).upsertIncrement(eq(userId), any(), eq(deckId), eq(1), eq(0), eq(1));
        verify(statsRepository).upsertIncrementAll(eq(userId), any(), eq(1), eq(0), eq(1));
    }

    @Test
    void incrementFromEventCountsNewCardLearningOnlyWhenFamiliar() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();

        service.incrementFromEvent(userId, deckId, LocalDateTime.now(), true, "VAGUE");

        verify(statsRepository).upsertIncrement(eq(userId), any(), eq(deckId), eq(0), eq(0), eq(1));
        verify(statsRepository).upsertIncrementAll(eq(userId), any(), eq(0), eq(0), eq(1));
    }

    @Test
    void getTrendReturnsPreAggregatedRowsFillingGapsWithZeros() {
        UUID userId = UUID.randomUUID();
        LocalTime refreshTime = LocalTime.of(4, 0);
        LocalDate today = LocalDate.now();

        DailyReviewStats row = new DailyReviewStats();
        row.setUserId(userId);
        row.setStatDate(today.minusDays(1));
        row.setDeckId(null);
        row.setReviewedCount(3);
        row.setLearnedCount(1);
        when(statsRepository.findByUserIdAndStatDateBetweenOrderByStatDateAsc(
                userId, today.minusDays(4), today)).thenReturn(List.of(row));

        var trend = service.getTrend(userId, refreshTime, 5);

        assertEquals(5, trend.size());
        assertEquals(3, trend.get(3).getReviewed());
        assertEquals(1, trend.get(3).getLearned());
        assertEquals(0, trend.get(4).getReviewed());
        assertEquals(today, trend.get(4).getDate());
    }

    @Test
    void getTrendReturnsEmptyWhenNoAllRowPresent() {
        UUID userId = UUID.randomUUID();
        LocalTime refreshTime = LocalTime.of(4, 0);
        LocalDate today = LocalDate.now();

        DailyReviewStats deckRow = new DailyReviewStats();
        deckRow.setUserId(userId);
        deckRow.setStatDate(today);
        deckRow.setDeckId(UUID.randomUUID()); // 只有卡组行、无全量行
        deckRow.setReviewedCount(1);
        deckRow.setLearnedCount(0);
        when(statsRepository.findByUserIdAndStatDateBetweenOrderByStatDateAsc(
                userId, today.minusDays(4), today)).thenReturn(List.of(deckRow));

        var trend = service.getTrend(userId, refreshTime, 5);

        assertEquals(0, trend.size());
    }

    @Test
    void getTodayCountsReturnsEmptyWhenNoAllRow() {
        UUID userId = UUID.randomUUID();
        when(statsRepository.findByUserIdAndStatDateAndDeckIdIsNull(any(), any()))
                .thenReturn(Optional.empty());

        Optional<int[]> counts = service.getTodayCounts(userId, LocalTime.of(4, 0));

        assertEquals(Optional.empty(), counts);
    }

    @Test
    void rebuildUserRebuildsAllLookbackDays() {
        UUID userId = UUID.randomUUID();

        int rebuilt = service.rebuildUser(userId);

        assertEquals(400, rebuilt);
        verify(statsRepository, never()).upsertIncrement(any(), any(), any(), anyInt(), anyInt(), anyInt());
        verify(statsRepository, never()).upsertIncrementAll(any(), any(), anyInt(), anyInt(), anyInt());
    }
}
