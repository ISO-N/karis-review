package top.kariscode.karisreview.common.etag;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserEtagServiceTest {

    @Mock
    private JdbcTemplate jdbcTemplate;

    private UserEtagService service;

    @BeforeEach
    void setUp() {
        service = new UserEtagService(jdbcTemplate);
        lenient().when(jdbcTemplate.queryForObject(
                eq("SELECT refresh_time FROM users WHERE id = ?"),
                eq(String.class),
                any(UUID.class))).thenReturn("04:00:00");
    }

    @Test
    void etagChangesWhenEventSequenceChanges() {
        UUID userId = UUID.randomUUID();
        when(jdbcTemplate.queryForObject(
                eq("SELECT COALESCE(MAX(event_seq), 0) FROM sync_events WHERE user_id = ?"),
                eq(Long.class),
                eq(userId))).thenReturn(1L);
        String first = service.decksEtag(userId);

        when(jdbcTemplate.queryForObject(
                eq("SELECT COALESCE(MAX(event_seq), 0) FROM sync_events WHERE user_id = ?"),
                eq(Long.class),
                eq(userId))).thenReturn(2L);
        String second = service.decksEtag(userId);

        assertNotEquals(first, second);
        assertTrue(first.startsWith("W/\"karis-review-api-v1-decks-1-"));
    }

    @Test
    void deckStatsEtagIncludesDeckId() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        when(jdbcTemplate.queryForObject(
                eq("SELECT COALESCE(MAX(event_seq), 0) FROM sync_events WHERE user_id = ?"),
                eq(Long.class),
                eq(userId))).thenReturn(3L);

        String etag = service.deckStatsEtag(userId, deckId);

        assertTrue(etag.contains("deck-stats"));
        assertTrue(etag.endsWith("-" + deckId + "\""));
    }

    @Test
    void overviewEtagHasNoDeckSuffix() {
        UUID userId = UUID.randomUUID();
        when(jdbcTemplate.queryForObject(
                eq("SELECT COALESCE(MAX(event_seq), 0) FROM sync_events WHERE user_id = ?"),
                eq(Long.class),
                eq(userId))).thenReturn(0L);

        String etag = service.overviewEtag(userId);

        assertTrue(etag.contains("-overview-0-"));
        assertTrue(etag.endsWith("\""));
    }
}
