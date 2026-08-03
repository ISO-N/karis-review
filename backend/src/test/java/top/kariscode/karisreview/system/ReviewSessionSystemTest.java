package top.kariscode.karisreview.system;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;

import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ReviewSessionSystemTest extends SystemTestSupport {

    @Test
    void sessionSupportsCursorPagingDeleteAndExpiry() {
        TestAccount user = register("session");
        String deckId = text(data("POST", "/decks", user.token(), Map.of("name", "会话卡组")), "id");
        String first = text(data("POST", "/decks/" + deckId + "/cards", user.token(),
                Map.of("front", "一", "back", "A")), "id");
        String second = text(data("POST", "/decks/" + deckId + "/cards", user.token(),
                Map.of("front", "二", "back", "B")), "id");
        String third = text(data("POST", "/decks/" + deckId + "/cards", user.token(),
                Map.of("front", "三", "back", "C")), "id");
        backdateCardForUser(user.email(), first);
        backdateCardForUser(user.email(), second);
        backdateCardForUser(user.email(), third);

        JsonNode created = data("POST", "/review/sessions", user.token(),
                Map.of("mode", "due", "deck_id", deckId, "batch_size", 2));
        String sessionId = text(created, "session_id");
        assertEquals(3, created.get("total").asInt());
        assertEquals(2, created.get("cards").size());
        assertTrue(created.get("has_more").asBoolean());

        JsonNode next = data("GET", "/review/sessions/" + sessionId + "?cursor=2&limit=2",
                user.token(), null);
        assertEquals(1, next.get("cards").size());
        assertFalse(next.get("has_more").asBoolean());

        data("DELETE", "/review/sessions/" + sessionId, user.token(), null);
        call("GET", "/review/sessions/" + sessionId, user.token(), null, 404);

        JsonNode expired = data("POST", "/review/sessions", user.token(),
                Map.of("mode", "due", "deck_id", deckId, "batch_size", 2));
        String expiredId = text(expired, "session_id");
        jdbcTemplate.update("UPDATE review_sessions SET expires_at = NOW() - INTERVAL '1 hour' WHERE id = ?",
                UUID.fromString(expiredId));
        call("GET", "/review/sessions/" + expiredId, user.token(), null, 410);
    }

    @Test
    void sessionIsNotAccessibleByAnotherUser() {
        TestAccount owner = register("session-owner");
        TestAccount other = register("session-other");
        String deckId = text(data("POST", "/decks", owner.token(), Map.of("name", "私有会话")), "id");
        String cardId = text(data("POST", "/decks/" + deckId + "/cards", owner.token(),
                Map.of("front", "私有", "back", "A")), "id");
        backdateCardForUser(owner.email(), cardId);

        JsonNode created = data("POST", "/review/sessions", owner.token(),
                Map.of("mode", "due", "batch_size", 10));
        String sessionId = text(created, "session_id");

        call("GET", "/review/sessions/" + sessionId, other.token(), null, 404);
        call("DELETE", "/review/sessions/" + sessionId, other.token(), null, 404);
    }
}
