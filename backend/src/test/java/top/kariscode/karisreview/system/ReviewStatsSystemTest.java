package top.kariscode.karisreview.system;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import top.kariscode.karisreview.common.util.DateUtils;

import java.time.LocalTime;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ReviewStatsSystemTest extends SystemTestSupport {

    @Test
    void newCardLearningAndOverviewStatsFlow() {
        TestAccount userA = register("review-a");
        TestAccount userB = register("review-b");
        String deckId = text(createDeck(userA.token(), "学习"), "id");
        String card1 = text(createCard(userA.token(), deckId, "单词一", "释义一"), "id");
        String card2 = text(createCard(userA.token(), deckId, "单词二", "释义二"), "id");

        JsonNode limited = data("GET", "/review/new?limit=1", userA.token(), null);
        assertEquals(1, limited.size());

        JsonNode rated = data("POST", "/review/" + card1 + "/rate", userA.token(),
                Map.of("rating", "FAMILIAR"));
        assertEquals(1, rated.get("stage_after").asInt());
        assertFalse(rated.get("learning_mode").asBoolean());
        assertEquals(DateUtils.calculateToday(LocalTime.of(4, 0)).plusDays(1).toString(),
                text(rated, "next_review_date"));

        data("POST", "/review/" + card2 + "/rate", userA.token(),
                Map.of("rating", "FAMILIAR"));

        JsonNode overview = data("GET", "/stats/overview", userA.token(), null);
        assertEquals(2, overview.get("total_cards").asInt());
        assertEquals(1, overview.get("total_decks").asInt());
        assertTrue(overview.get("reviewed_today").asInt() >= 2);
        assertEquals(0, data("GET", "/review/new", userB.token(), null).size());
    }

    @Test
    void forgetRelearningAndVagueReentryUseSchedulingRules() {
        TestAccount user = register("review-schedule");
        String deckId = text(createDeck(user.token(), "排期"), "id");
        String cardId = text(createCard(user.token(), deckId, "排期卡", "反面"), "id");

        backdateCardForUser(user.email(), cardId);
        JsonNode due = data("GET", "/review/due?deck_id=" + deckId, user.token(), null);
        assertEquals(1, due.size());

        JsonNode forget = data("POST", "/review/" + cardId + "/rate", user.token(),
                Map.of("rating", "FORGET"));
        assertEquals(0, forget.get("stage_after").asInt());
        assertTrue(forget.get("learning_mode").asBoolean());
        assertEquals(DateUtils.calculateToday(LocalTime.of(4, 0)).toString(),
                text(forget, "next_review_date"));

        for (int i = 0; i < 4; i++) {
            JsonNode result = data("POST", "/review/" + cardId + "/rate", user.token(),
                    Map.of("rating", "FAMILIAR"));
            assertTrue(result.get("learning_mode").asBoolean());
        }
        JsonNode completedForget = data("POST", "/review/" + cardId + "/rate", user.token(),
                Map.of("rating", "FAMILIAR"));
        assertFalse(completedForget.get("learning_mode").asBoolean());
        assertEquals(1, completedForget.get("stage_after").asInt());

        setCardStageForUser(user.email(), cardId, 4, false);
        backdateCardForUser(user.email(), cardId);
        JsonNode vague = data("POST", "/review/" + cardId + "/rate", user.token(),
                Map.of("rating", "VAGUE"));
        assertEquals(3, vague.get("stage_after").asInt());
        assertTrue(vague.get("learning_mode").asBoolean());
        assertEquals(4, data("GET", "/cards/" + cardId, user.token(), null)
                .get("reentry_stage").asInt());

        data("POST", "/review/" + cardId + "/rate", user.token(), Map.of("rating", "FAMILIAR"));
        data("POST", "/review/" + cardId + "/rate", user.token(), Map.of("rating", "FAMILIAR"));
        JsonNode completedVague = data("POST", "/review/" + cardId + "/rate", user.token(),
                Map.of("rating", "FAMILIAR"));
        assertFalse(completedVague.get("learning_mode").asBoolean());
        assertEquals(4, completedVague.get("stage_after").asInt());
        assertEquals(DateUtils.calculateToday(LocalTime.of(4, 0)).plusDays(3).toString(),
                text(completedVague, "next_review_date"));
    }

    @Test
    void deckStatsAndTrendReflectReviews() {
        TestAccount user = register("review-stats");
        String deckId = text(createDeck(user.token(), "统计牌组"), "id");
        String cardId = text(createCard(user.token(), deckId, "统计卡", "反面"), "id");
        data("POST", "/review/" + cardId + "/rate", user.token(),
                Map.of("rating", "FAMILIAR"));

        JsonNode deckStats = data("GET", "/stats/deck/" + deckId, user.token(), null);
        assertEquals("统计牌组", text(deckStats, "deck_name"));
        assertEquals(1, deckStats.get("total_cards").asInt());
        assertEquals(1, deckStats.get("reviewed_today").asInt());

        JsonNode trend = data("GET", "/stats/trend?days=7", user.token(), null);
        assertEquals(7, trend.size());
        assertTrue(trend.get(trend.size() - 1).get("reviewed").asInt() >= 1);
    }

    private JsonNode createDeck(String token, String name) {
        return data("POST", "/decks", token, Map.of("name", name));
    }

    private JsonNode createCard(String token, String deckId, String front, String back) {
        return data("POST", "/decks/" + deckId + "/cards", token,
                Map.of("front", front, "back", back));
    }
}
