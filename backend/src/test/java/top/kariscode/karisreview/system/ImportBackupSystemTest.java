package top.kariscode.karisreview.system;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ImportBackupSystemTest extends SystemTestSupport {

    @Test
    void previewImportExportAndRestoreWorkOverApi() {
        TestAccount user = register("backup");
        String deckId = text(createDeck(user.token(), "原始牌组"), "id");

        JsonNode preview = data("POST", "/decks/" + deckId + "/cards/import/preview",
                user.token(), Map.of("content", """
                        [
                          {"front":"正面一","back":"反面一"},
                          {"front":"","back":"反面二"}
                        ]
                        """));
        assertEquals(2, preview.get("total").asInt());
        assertEquals(1, preview.get("valid_count").asInt());
        assertEquals(1, preview.get("invalid_count").asInt());

        JsonNode imported = data("POST", "/decks/" + deckId + "/cards/import", user.token(),
                Map.of("cards", List.of(
                        Map.of("front", "正面一", "back", "反面一"),
                        Map.of("front", "正面二", "back", "反面二"))));
        assertEquals(2, imported.get("imported_cards").asInt());

        String cardId = firstCardId(user.token(), deckId);
        data("POST", "/review/" + cardId + "/rate", user.token(),
                Map.of("rating", "FAMILIAR"));

        JsonNode export = data("POST", "/backup/export", user.token(), null);
        assertTrue(export.has("backup_id"));
        assertTrue(export.get("data").get("decks").size() >= 1);
        assertTrue(export.get("data").get("review_logs").size() >= 1);

        String tempDeckId = text(createDeck(user.token(), "临时牌组"), "id");
        data("POST", "/decks/" + tempDeckId + "/cards", user.token(),
                Map.of("front", "临时", "back", "数据"));
        Map<String, Object> backupData = objectMapper.convertValue(
                export.get("data"), Map.class);

        JsonNode restored = data("POST", "/backup/import", user.token(),
                Map.of("data", backupData));
        assertEquals(1, restored.get("imported_decks").asInt());
        assertEquals(2, restored.get("imported_cards").asInt());
        assertTrue(restored.get("imported_review_logs").asInt() >= 1);

        JsonNode decks = data("GET", "/decks", user.token(), null);
        assertEquals(1, decks.size());
        assertEquals("原始牌组", text(decks.get(0), "name"));
        assertEquals(2, decks.get(0).get("card_count").asInt());
    }

    @Test
    void invalidImportIsRejectedWithoutPartialWrite() {
        TestAccount user = register("import-invalid");
        String deckId = text(createDeck(user.token(), "导入牌组"), "id");

        JsonNode rejected = call("POST", "/decks/" + deckId + "/cards/import", user.token(),
                Map.of("cards", List.of(
                        Map.of("front", "有效", "back", "反面"),
                        Map.of("front", "  ", "back", "反面"))), 400);
        assertEquals(400, rejected.get("code").asInt());

        JsonNode cards = data("GET", "/decks/" + deckId + "/cards", user.token(), null);
        assertEquals(0, cards.get("total_elements").asInt());
    }

    private JsonNode createDeck(String token, String name) {
        return data("POST", "/decks", token, Map.of("name", name));
    }

    private String firstCardId(String token, String deckId) {
        JsonNode cards = data("GET", "/decks/" + deckId + "/cards", token, null);
        return text(cards.get("content").get(0), "id");
    }
}
