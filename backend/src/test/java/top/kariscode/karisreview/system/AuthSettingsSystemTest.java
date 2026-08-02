package top.kariscode.karisreview.system;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class AuthSettingsSystemTest extends SystemTestSupport {

    @Test
    void registerLoginAndSettingsFlowWorkOverRealApi() {
        TestAccount account = register("auth");

        JsonNode settings = data("GET", "/settings", account.token(), null);
        assertEquals(account.email(), text(settings, "email"));
        assertEquals("04:00:00", text(settings, "refresh_time"));

        JsonNode updated = data("PUT", "/settings", account.token(),
                Map.of("refresh_time", "03:00:00"));
        assertEquals("03:00:00", text(updated, "refresh_time"));

        JsonNode reRead = data("GET", "/settings", account.token(), null);
        assertEquals("03:00:00", text(reRead, "refresh_time"));

        JsonNode logout = call("POST", "/auth/logout", account.token(), null, 200);
        assertEquals("已登出", text(logout, "message"));

        TestAccount loggedIn = login(account.email());
        assertNotNull(loggedIn.token());
        assertEquals(account.email(), loggedIn.email());
    }

    @Test
    void duplicateRegistrationAndWrongPasswordAreRejected() {
        TestAccount account = register("duplicate");

        JsonNode duplicate = call("POST", "/auth/register", null, Map.of(
                "email", account.email(),
                "password", PASSWORD), 400);
        assertEquals(400, duplicate.get("code").asInt());
        assertEquals("邮箱已被注册", text(duplicate, "message"));

        JsonNode wrongPassword = call("POST", "/auth/login", null, Map.of(
                "email", account.email(),
                "password", "wrong-password"), 401);
        assertEquals(401, wrongPassword.get("code").asInt());
        assertEquals("邮箱或密码错误", text(wrongPassword, "message"));
    }
}
