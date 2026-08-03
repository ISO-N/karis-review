package top.kariscode.karisreview.system;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class LogSystemTest extends SystemTestSupport {

    @Test
    void registrationLogsAreVisibleAndFilterable() {
        TestAccount user = register("log");

        JsonNode logs = data("GET", "/logs?level=INFO&category=AUTH", user.token(), null);

        assertTrue(logs.get("content").size() > 0);
        JsonNode first = logs.get("content").get(0);
        assertEquals("INFO", first.get("level").asText());
        assertEquals("AUTH", first.get("category").asText());
    }

    @Test
    void logsArePagedAndFilteredByCategory() {
        TestAccount user = register("log-page");
        data("POST", "/decks", user.token(), Map.of("name", "日志卡组"));

        JsonNode logs = data("GET", "/logs?page=0&size=10", user.token(), null);

        assertTrue(logs.has("content"));
        assertTrue(logs.has("page"));
        assertTrue(logs.has("total_pages"));
    }
}
