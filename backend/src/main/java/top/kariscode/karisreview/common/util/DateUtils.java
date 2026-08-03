package top.kariscode.karisreview.common.util;

import top.kariscode.karisreview.config.AppTimeZone;

import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.OffsetDateTime;
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
        return calculateToday(refreshTime, LocalDateTime.now(AppTimeZone.get()));
    }

    public static LocalDate calculateToday(LocalTime refreshTime, Clock clock) {
        return calculateToday(refreshTime, LocalDateTime.now(clock));
    }

    public static LocalDate calculateToday(LocalTime refreshTime, ZoneId zone) {
        return calculateToday(refreshTime, LocalDateTime.now(zone));
    }

    public static LocalDate calculateToday(LocalTime refreshTime, LocalDateTime now) {
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
        return calculateNextReviewDate(intervalDays, refreshTime,
                LocalDateTime.now(AppTimeZone.get()));
    }

    public static LocalDate calculateNextReviewDate(int intervalDays, LocalTime refreshTime, Clock clock) {
        return calculateNextReviewDate(intervalDays, refreshTime, LocalDateTime.now(clock));
    }

    public static LocalDate calculateNextReviewDate(int intervalDays, LocalTime refreshTime, ZoneId zone) {
        return calculateNextReviewDate(intervalDays, refreshTime, LocalDateTime.now(zone));
    }

    public static LocalDate calculateNextReviewDate(int intervalDays, LocalTime refreshTime, LocalDateTime now) {
        return calculateToday(refreshTime, now).plusDays(intervalDays);
    }

    public static LocalDateTime now() {
        return LocalDateTime.now(AppTimeZone.get());
    }

    public static LocalDateTime toBusinessLocalDateTime(OffsetDateTime value) {
        return value.atZoneSameInstant(AppTimeZone.get()).toLocalDateTime();
    }
}
