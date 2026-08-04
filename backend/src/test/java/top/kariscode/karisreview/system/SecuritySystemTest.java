package top.kariscode.karisreview.system;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.springframework.http.ResponseEntity;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class SecuritySystemTest extends SystemTestSupport {

    @Test
    void protectedEndpointsRejectMissingAndInvalidTokens() {
        JsonNode missing = call("GET", "/decks", null, null, 401);
        assertEquals(401, missing.get("code").asInt());
        assertEquals("Not logged in or token expired", text(missing, "message"));

        JsonNode invalid = call("GET", "/decks", "invalid-token", null, 401);
        assertEquals(401, invalid.get("code").asInt());
    }

    @Test
    void registerAndLoginDoNotRequireAuthentication() {
        TestAccount account = register("security");
        assertNotNull(account.token());

        JsonNode login = data("POST", "/auth/login", null, Map.of(
                "email", account.email(),
                "password", PASSWORD));
        assertNotNull(login.get("token").asText());
    }

    @Test
    void logoutRequiresAuthentication() {
        TestAccount account = register("security-logout");
        assertEquals(401, call("POST", "/auth/logout", null, null, 401).get("code").asInt());
        assertEquals(200, call("POST", "/auth/logout", account.token(), null, 200).get("code").asInt());
    }

    @Test
    void crossUserAccessReturns404NotData() {
        TestAccount userA = register("security-a");
        TestAccount userB = register("security-b");
        JsonNode deck = data("POST", "/decks", userA.token(), Map.of("name", "私有牌组"));
        String deckId = text(deck, "id");

        assertEquals(404, call("GET", "/decks/" + deckId + "/cards",
                userB.token(), null, 404).get("code").asInt());
        assertEquals(404, call("PUT", "/decks/" + deckId, userB.token(),
                Map.of("name", "越权"), 404).get("code").asInt());
    }

    @Test
    void swaggerUiAndDocsArePublic() {
        ResponseEntity<String> index = restTemplate.getForEntity("/swagger-ui/index.html", String.class);
        assertEquals(200, index.getStatusCode().value());
        assertTrue(index.getBody() != null && index.getBody().contains("Swagger UI"));

        ResponseEntity<String> initializer = restTemplate.getForEntity("/swagger-ui/swagger-initializer.js", String.class);
        assertEquals(200, initializer.getStatusCode().value());
        assertTrue(initializer.getBody() != null && initializer.getBody().contains("../v3/api-docs"));

        ResponseEntity<String> docs = restTemplate.getForEntity("/v3/api-docs", String.class);
        assertEquals(200, docs.getStatusCode().value());
        assertNotNull(docs.getBody());
    }
}
