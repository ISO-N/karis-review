package top.kariscode.karisreview.common.util;

import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

import static org.junit.jupiter.api.Assertions.assertEquals;

class DateUtilsTest {

    private final LocalTime refreshTime = LocalTime.of(4, 0);

    @Test
    void beforeRefreshTimeBelongsToPreviousDay() {
        LocalDateTime now = LocalDateTime.of(2025, 8, 2, 3, 59);

        LocalDate today = DateUtils.calculateToday(refreshTime, now);

        assertEquals(LocalDate.of(2025, 8, 1), today);
    }

    @Test
    void exactlyAtRefreshTimeBelongsToSameDay() {
        LocalDateTime now = LocalDateTime.of(2025, 8, 2, 4, 0);

        LocalDate today = DateUtils.calculateToday(refreshTime, now);

        assertEquals(LocalDate.of(2025, 8, 2), today);
    }

    @Test
    void afterRefreshTimeBelongsToSameDay() {
        LocalDateTime now = LocalDateTime.of(2025, 8, 2, 23, 59);

        LocalDate today = DateUtils.calculateToday(refreshTime, now);

        assertEquals(LocalDate.of(2025, 8, 2), today);
    }

    @Test
    void refreshBoundaryWorksAcrossMonthAndYear() {
        assertEquals(
                LocalDate.of(2024, 12, 31),
                DateUtils.calculateToday(refreshTime, LocalDateTime.of(2025, 1, 1, 3, 0)));
        assertEquals(
                LocalDate.of(2025, 1, 1),
                DateUtils.calculateToday(refreshTime, LocalDateTime.of(2025, 1, 1, 4, 0)));
    }

    @Test
    void nextReviewDateUsesCalculatedToday() {
        LocalDateTime afterRefresh = LocalDateTime.of(2025, 1, 1, 23, 0);
        LocalDateTime beforeRefresh = LocalDateTime.of(2025, 1, 1, 3, 0);

        assertEquals(
                LocalDate.of(2025, 1, 8),
                DateUtils.calculateNextReviewDate(7, refreshTime, afterRefresh));
        assertEquals(
                LocalDate.of(2025, 1, 7),
                DateUtils.calculateNextReviewDate(7, refreshTime, beforeRefresh));
    }
}
