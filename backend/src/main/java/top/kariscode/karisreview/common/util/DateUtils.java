package top.kariscode.karisreview.common.util;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;

public class DateUtils {

    private DateUtils() {}

    /**
     * Calculate the "today" date based on the user's refresh time.
     * If current time is before refresh time, "today" is the previous calendar day.
     * Example: refresh_time = 04:00, current = 2025-08-02 03:00 → today = 2025-08-01
     *          refresh_time = 04:00, current = 2025-08-02 10:00 → today = 2025-08-02
     */
    public static LocalDate calculateToday(LocalTime refreshTime) {
        LocalDateTime now = LocalDateTime.now(ZoneId.of("UTC"));
        LocalDateTime todayRefresh = now.toLocalDate().atTime(refreshTime);
        if (now.isBefore(todayRefresh)) {
            return now.toLocalDate().minusDays(1);
        }
        return now.toLocalDate();
    }

    /**
     * Calculate the next review date given a stage's interval in days.
     * Based on the user's refresh time.
     */
    public static LocalDate calculateNextReviewDate(int intervalDays, LocalTime refreshTime) {
        LocalDate today = calculateToday(refreshTime);
        return today.plusDays(intervalDays);
    }
}