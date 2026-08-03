package top.kariscode.karisreview.system;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
class SyncSystemTest extends SystemTestSupport {

    @Test
    void deltaReturnsChangesAndDeletesAfterCursor() {
        TestAccount user = register("sync-delta");
        JsonNode full = data("GET", "/sync/bootstrap", user.token(), null);
        long cursor = full.get("event_cursor").asLong();

        String deckId = text(createDeck(user.token(), "增量牌组"), "id");
        text(createCard(user.token(), deckId, "增量卡", "反面"), "id");

        JsonNode delta = data("GET", "/sync/bootstrap?event_cursor=" + cursor,
                user.token(), null);
        assertTrue(delta.get("decks").size() > 0 || delta.get("changed_cards").size() > 0);
        assertTrue(delta.get("event_cursor").asLong() > cursor);

        long nextCursor = delta.get("event_cursor").asLong();
        data("DELETE", "/decks/" + deckId, user.token(), null);

        JsonNode deleteDelta = data("GET", "/sync/bootstrap?event_cursor=" + nextCursor,
                user.token(), null);
        assertTrue(deleteDelta.get("deleted_deck_ids").toString().contains(deckId));
    }

    @Test
    void settingsChangeAppearsInDeltaUser() {
        TestAccount user = register("sync-settings");
        JsonNode full = data("GET", "/sync/bootstrap", user.token(), null);
        long cursor = full.get("event_cursor").asLong();

        data("PUT", "/settings", user.token(), Map.of("refresh_time", "03:00:00"));

        JsonNode delta = data("GET", "/sync/bootstrap?event_cursor=" + cursor,
                user.token(), null);
        assertEquals("03:00:00", delta.get("user").get("refresh_time").asText());
        assertTrue(delta.get("event_cursor").asLong() > cursor);
    }

    @Test
    void deletedCardIdAppearsInDelta() {
        TestAccount user = register("sync-del");
        JsonNode full = data("GET", "/sync/bootstrap", user.token(), null);
        long cursor = full.get("event_cursor").asLong();
        String deckId = text(createDeck(user.token(), "删除卡牌组"), "id");
        String cardId = text(createCard(user.token(), deckId, "待删卡", "反面"), "id");

        data("DELETE", "/cards/" + cardId, user.token(), null);

        JsonNode delta = data("GET", "/sync/bootstrap?event_cursor=" + cursor,
                user.token(), null);
        assertTrue(delta.get("deleted_card_ids").toString().contains(cardId));
    }

    @Test
    void staleCursorRequiresFullReset() {
        TestAccount user = register("sync-stale");
        data("GET", "/sync/bootstrap", user.token(), null);

        JsonNode delta = data("GET", "/sync/bootstrap?event_cursor=999999999",
                user.token(), null);
        assertTrue(delta.get("reset_required").asBoolean());
        assertTrue(delta.get("event_cursor").asLong() < 999999999L);
    }

    private JsonNode createDeck(String token, String name) {
        return data("POST", "/decks", token, Map.of("name", name));
    }

    private JsonNode createCard(String token, String deckId, String front, String back) {
        return data("POST", "/decks/" + deckId + "/cards", token,
                Map.of("front", front, "back", back));
    }
}
