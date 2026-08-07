package top.kariscode.karisreview.common.etag;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import top.kariscode.karisreview.common.util.DateUtils;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

@Service
public class UserEtagService {

    private static final String VERSION_PREFIX = "karis-review-api-v1";

    private final JdbcTemplate jdbcTemplate;

    public UserEtagService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public String decksEtag(UUID userId) {
        return etag("decks", userId, null);
    }

    public String overviewEtag(UUID userId) {
        return etag("overview", userId, null);
    }

    public String deckStatsEtag(UUID userId, UUID deckId) {
        return etag("deck-stats", userId, deckId);
    }

    public String trendEtag(UUID userId) {
        return etag("trend", userId, null);
    }

    private String etag(String kind, UUID userId, UUID deckId) {
        long eventSeq = latestEventSeq(userId);
        LocalDate today = todayFor(userId);
        String suffix = deckId == null ? "" : "-" + deckId;
        return "W/\"" + VERSION_PREFIX + "-" + kind + "-" + eventSeq
                + "-" + today + suffix + "\"";
    }

    private long latestEventSeq(UUID userId) {
        Long seq = jdbcTemplate.queryForObject(
                "SELECT COALESCE(MAX(event_seq), 0) FROM sync_events WHERE user_id = ?",
                Long.class, userId);
        return seq == null ? 0 : seq;
    }

    private LocalDate todayFor(UUID userId) {
        String refreshTime = jdbcTemplate.queryForObject(
                "SELECT refresh_time FROM users WHERE id = ?", String.class, userId);
        return DateUtils.calculateToday(LocalTime.parse(refreshTime));
    }
}
