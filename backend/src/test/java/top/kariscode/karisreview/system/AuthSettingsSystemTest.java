package top.kariscode.karisreview.system;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class AuthSettingsSystemTest extends SystemTestSupport {

    @Test
    void registerLoginAndSettingsFlowWorkOverRealApi() {
        JsonNode config = data("GET", "/auth/config", null, null);
        assertEquals(false, config.get("invite_code_required").asBoolean());

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
        assertEquals("auth.logout.success", text(logout, "message"));

        TestAccount loggedIn = login(account.email());
        assertNotNull(loggedIn.token());
        assertEquals(account.email(), loggedIn.email());
    }

    @Test
    void duplicateRegistrationAndWrongPasswordAreRejected() {
        TestAccount account = register("duplicate");

        // 已注册邮箱不能再发注册验证码
        JsonNode duplicateCode = call("POST", "/auth/register-code", null, Map.of(
                "email", account.email()), 400);
        assertEquals(400, duplicateCode.get("code").asInt());
        assertEquals("Email already registered", text(duplicateCode, "message"));

        JsonNode duplicate = call("POST", "/auth/register", null, Map.of(
                "email", account.email(),
                "password", PASSWORD,
                "verification_code", "123456"), 400);
        assertEquals(400, duplicate.get("code").asInt());
        assertEquals("Email already registered", text(duplicate, "message"));

        JsonNode wrongPassword = call("POST", "/auth/login", null, Map.of(
                "email", account.email(),
                "password", "wrong-password"), 401);
        assertEquals(401, wrongPassword.get("code").asInt());
        assertEquals("Incorrect email or password", text(wrongPassword, "message"));
    }

    @Test
    void forgotPasswordResetsViaEmailCode() {
        TestAccount account = register("forgot");

        // 发找回验证码，从库中读取（NoopMailSender 只打日志）
        data("POST", "/auth/password/reset-code", null, Map.of("email", account.email()));
        String code = jdbcTemplate.queryForObject(
                "SELECT code FROM email_verification_codes WHERE email = ? AND purpose = 'RESET' AND used = FALSE ORDER BY created_at DESC LIMIT 1",
                String.class, account.email());
        assertNotNull(code);

        JsonNode reset = call("POST", "/auth/password/reset", null, Map.of(
                "email", account.email(),
                "code", code,
                "new_password", "reset-password-123"), 200);
        assertEquals("auth.password.reset", text(reset, "message"));

        // 旧密码登录失败，新密码登录成功
        JsonNode oldLogin = call("POST", "/auth/login", null, Map.of(
                "email", account.email(),
                "password", PASSWORD), 401);
        assertEquals(401, oldLogin.get("code").asInt());

        JsonNode newLogin = data("POST", "/auth/login", null, Map.of(
                "email", account.email(),
                "password", "reset-password-123"));
        assertNotNull(newLogin.get("token"));
    }

    @Test
    void forgotPasswordRejectsWrongCode() {
        TestAccount account = register("forgot-wrong");

        data("POST", "/auth/password/reset-code", null, Map.of("email", account.email()));

        JsonNode reset = call("POST", "/auth/password/reset", null, Map.of(
                "email", account.email(),
                "code", "000000",
                "new_password", "reset-password-123"), 400);
        assertEquals(400, reset.get("code").asInt());
        assertEquals("Invalid verification code", text(reset, "message"));
    }

    @Test
    void changePasswordInvalidatesOldPassword() {
        TestAccount account = register("change-pw");

        JsonNode changed = call("PUT", "/auth/password", account.token(), Map.of(
                "current_password", PASSWORD,
                "new_password", "new-password-123"), 200);
        assertEquals("auth.password.changed", text(changed, "message"));

        // 旧密码登录失败，新密码登录成功
        JsonNode oldLogin = call("POST", "/auth/login", null, Map.of(
                "email", account.email(),
                "password", PASSWORD), 401);
        assertEquals(401, oldLogin.get("code").asInt());

        JsonNode newLogin = data("POST", "/auth/login", null, Map.of(
                "email", account.email(),
                "password", "new-password-123"));
        assertNotNull(newLogin.get("token"));
    }

    @Test
    void changePasswordRejectsWrongCurrentPassword() {
        TestAccount account = register("change-pw-wrong");

        JsonNode failed = call("PUT", "/auth/password", account.token(), Map.of(
                "current_password", "wrong-current",
                "new_password", "new-password-123"), 400);
        assertEquals(400, failed.get("code").asInt());
        assertEquals("Current password is incorrect", text(failed, "message"));
    }
}