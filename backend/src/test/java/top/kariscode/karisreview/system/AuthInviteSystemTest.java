package top.kariscode.karisreview.system;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.springframework.test.context.TestPropertySource;

import java.util.Map;
import java.util.UUID;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

@TestPropertySource(properties = {
        "auth.invite.enabled=true",
        "auth.invite.code=system-test-invite"
})
class AuthInviteSystemTest extends SystemTestSupport {

    @Test
    void configAndRegistrationValidateInviteCode() {
        JsonNode config = data("GET", "/auth/config", null, null);
        assertTrue(config.get("invite_code_required").asBoolean());

        JsonNode missing = call("POST", "/auth/register", null, Map.of(
                "email", "system-test-invite-missing-" + UUID.randomUUID() + "@example.com",
                "password", PASSWORD), 400);
        assertEquals("请输入邀请码", text(missing, "message"));

        JsonNode wrong = call("POST", "/auth/register", null, Map.of(
                "email", "system-test-invite-wrong-" + UUID.randomUUID() + "@example.com",
                "password", PASSWORD,
                "invite_code", "wrong-code"), 400);
        assertEquals("邀请码无效", text(wrong, "message"));

        TestAccount account = register("invite", "system-test-invite");
        assertNotNull(account.token());
    }
}
