package top.kariscode.karisreview.system;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;

import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class PerformanceSmokeSystemTest extends SystemTestSupport {

    @Test
    void thousandCardDataVolumeSmokeTest() {
        TestAccount user = register("perf");
        UUID userId = userId(user.email());
        String deckId = text(data("POST", "/decks", user.token(), Map.of("name", "千卡卡组")), "id");

        for (int i = 0; i < 1001; i++) {
            UUID cardId = UUID.randomUUID();
            jdbcTemplate.update("""
                    INSERT INTO cards
                        (id, deck_id, user_id, front, back, stage, consecutive_familiar,
                         next_review_date, learning_mode, reentry_stage, learning_step,
                         review_version, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, 0, 0, NULL, false, NULL, 0, 0, NOW(), NOW())
                    """, cardId, UUID.fromString(deckId), userId,
                    "批量卡 " + i, "反面 " + i);
        }

        JsonNode page = data("GET", "/decks/" + deckId + "/cards?page=0&size=100",
                user.token(), null);
        assertEquals(1001, page.get("total_elements").asInt());
        assertEquals(100, page.get("content").size());

        JsonNode search = data("GET", "/decks/" + deckId + "/cards?q=批量卡 1000&size=100",
                user.token(), null);
        assertEquals(1, search.get("total_elements").asInt());

        JsonNode overview = data("GET", "/stats/overview", user.token(), null);
        assertEquals(1001, overview.get("total_cards").asInt());
        assertEquals(1001, overview.get("new_cards").asInt());

        JsonNode newQueue = data("GET", "/review/new?limit=500", user.token(), null);
        assertEquals(500, newQueue.size());
    }
}
