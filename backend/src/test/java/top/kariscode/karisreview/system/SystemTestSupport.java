package top.kariscode.karisreview.system;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import top.kariscode.karisreview.common.util.DateUtils;

import java.time.LocalTime;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
public abstract class SystemTestSupport {

    protected static final String PASSWORD = "password123";
    protected static final String TEST_USER_PATTERN = "system-test-%@example.com";

    @Autowired
    protected TestRestTemplate restTemplate;

    @Autowired
    protected JdbcTemplate jdbcTemplate;

    @Autowired
    protected ObjectMapper objectMapper;

    @BeforeEach
    @AfterEach
    void cleanSystemTestUsers() {
        jdbcTemplate.update("DELETE FROM users WHERE email LIKE ?", TEST_USER_PATTERN);
    }

    protected TestAccount register(String prefix) {
        return register(prefix, "");
    }

    protected TestAccount register(String prefix, String inviteCode) {
        String email = "system-test-" + prefix + "-" + UUID.randomUUID() + "@example.com";
        JsonNode data = data("POST", "/auth/register", null, Map.of(
                "email", email,
                "password", PASSWORD,
                "invite_code", inviteCode));
        return new TestAccount(email, data.get("token").asText());
    }

    protected TestAccount login(String email) {
        JsonNode data = data("POST", "/auth/login", null, Map.of(
                "email", email,
                "password", PASSWORD));
        return new TestAccount(email, data.get("token").asText());
    }

    protected JsonNode data(String method, String path, String token, Object body) {
        return call(method, path, token, body, 200).get("data");
    }

    protected JsonNode call(String method, String path, String token, Object body, int expectedStatus) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        if (token != null) {
            headers.setBearerAuth(token);
        }
        HttpEntity<Object> entity = new HttpEntity<>(body, headers);
        ResponseEntity<String> response = restTemplate.exchange(
                "/api" + path, HttpMethod.valueOf(method), entity, String.class);
        assertEquals(expectedStatus, response.getStatusCode().value(),
                () -> "Unexpected status for " + method + " " + path + ": " + response.getBody());
        try {
            return objectMapper.readTree(response.getBody());
        } catch (Exception e) {
            throw new AssertionError("Invalid JSON response: " + response.getBody(), e);
        }
    }

    protected String text(JsonNode node, String field) {
        JsonNode value = node.get(field);
        assertNotNull(value, "Missing field " + field);
        return value.asText();
    }

    protected UUID userId(String email) {
        UUID id = jdbcTemplate.queryForObject(
                "SELECT id FROM users WHERE email = ?", UUID.class, email);
        assertNotNull(id);
        return id;
    }

    protected void backdateCardForUser(String email, String cardId) {
        jdbcTemplate.update(
                "UPDATE cards SET next_review_date = ? WHERE id = ? AND user_id = ?",
                DateUtils.calculateToday(LocalTime.of(4, 0)), UUID.fromString(cardId), userId(email));
    }

    protected void setCardStageForUser(String email, String cardId, int stage, boolean learningMode) {
        jdbcTemplate.update(
                "UPDATE cards SET stage = ?, learning_mode = ?, consecutive_familiar = 0, "
                        + "learning_step = 0, reentry_stage = NULL WHERE id = ? AND user_id = ?",
                stage, learningMode, UUID.fromString(cardId), userId(email));
    }

    protected record TestAccount(String email, String token) {}
}
