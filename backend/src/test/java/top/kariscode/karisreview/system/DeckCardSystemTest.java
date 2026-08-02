package top.kariscode.karisreview.system;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;

import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class DeckCardSystemTest extends SystemTestSupport {

    @Test
    void deckAndCardCrudIsScopedToCurrentUser() {
        TestAccount userA = register("deck-a");
        TestAccount userB = register("deck-b");

        JsonNode deck = createDeck(userA.token(), "日语 N5");
        String deckId = text(deck, "id");
        assertEquals("日语 N5", text(deck, "name"));
        assertEquals(0, deck.get("card_count").asInt());

        JsonNode decks = data("GET", "/decks", userA.token(), null);
        assertEquals(1, decks.size());
        assertEquals(0, data("GET", "/decks", userB.token(), null).size());

        JsonNode card = createCard(userA.token(), deckId, "ありがとう", "谢谢");
        String cardId = text(card, "id");
        assertEquals(0, card.get("stage").asInt());

        JsonNode cards = data("GET", "/decks/" + deckId + "/cards", userA.token(), null);
        assertEquals(1, cards.get("total_elements").asInt());

        assertEquals(404, call("GET", "/decks/" + deckId + "/cards",
                userB.token(), null, 404).get("code").asInt());
        assertEquals(404, call("GET", "/cards/" + cardId,
                userB.token(), null, 404).get("code").asInt());

        JsonNode updatedCard = data("PUT", "/cards/" + cardId, userA.token(),
                Map.of("front", "勉強する", "back", "学习"));
        assertEquals("勉強する", text(updatedCard, "front"));

        JsonNode updatedDeck = data("PUT", "/decks/" + deckId, userA.token(),
                Map.of("name", "日语 N5 改"));
        assertEquals("日语 N5 改", text(updatedDeck, "name"));

        JsonNode renamedCards = data("GET", "/decks/" + deckId + "/cards?filter=all",
                userA.token(), null);
        assertEquals("勉強する", renamedCards.get("content").get(0).get("front").asText());

        data("DELETE", "/cards/" + cardId, userA.token(), null);
        JsonNode afterCardDelete = data("GET", "/decks/" + deckId + "/cards",
                userA.token(), null);
        assertEquals(0, afterCardDelete.get("total_elements").asInt());

        data("DELETE", "/decks/" + deckId, userA.token(), null);
        assertEquals(0, data("GET", "/decks", userA.token(), null).size());
    }

    @Test
    void deletingDeckCascadesCardsAndReviewLogs() {
        TestAccount user = register("deck-delete");
        JsonNode deck = createDeck(user.token(), "待删除");
        String deckId = text(deck, "id");
        String cardId = text(createCard(user.token(), deckId, "正面", "反面"), "id");

        data("POST", "/review/" + cardId + "/rate", user.token(),
                Map.of("rating", "FAMILIAR"));
        data("DELETE", "/decks/" + deckId, user.token(), null);

        assertEquals(0, data("GET", "/decks", user.token(), null).size());
        Integer cards = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM cards WHERE user_id = ?",
                Integer.class, userId(user.email()));
        assertEquals(0, cards);
        Integer logs = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM review_logs WHERE user_id = ?",
                Integer.class, userId(user.email()));
        assertEquals(0, logs);
    }

    @Test
    void cardsCanBeFilteredByDueState() {
        TestAccount user = register("card-filter");
        JsonNode deck = createDeck(user.token(), "筛选");
        String deckId = text(deck, "id");
        String cardId = text(createCard(user.token(), deckId, "到期卡", "反面"), "id");

        backdateCardForUser(user.email(), cardId);

        JsonNode due = data("GET", "/decks/" + deckId + "/cards?filter=due",
                user.token(), null);
        assertEquals(1, due.get("total_elements").asInt());
        assertTrue(due.get("content").get(0).get("due").asBoolean());
    }

    private JsonNode createDeck(String token, String name) {
        return data("POST", "/decks", token, Map.of("name", name));
    }

    private JsonNode createCard(String token, String deckId, String front, String back) {
        return data("POST", "/decks/" + deckId + "/cards", token,
                Map.of("front", front, "back", back));
    }
}
