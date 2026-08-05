package top.kariscode.karisreview.config;

import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * JWT 多密钥轮换测试（WP-8）：签发用 active kid，旧密钥仍可验签（滚动期兼容）。
 */
class JwtProviderMultiKeyTest {

    private static final String SECRET_1 = "secret-one-256-bits-long-abcdefghijklmnopqrstuvwxyz1234";
    private static final String SECRET_2 = "secret-two-256-bits-long-abcdefghijklmnopqrstuvwxyz5678";

    @Test
    void tokenSignedWithActiveKidAndVerifiedByAllKeys() {
        JwtProvider provider = new JwtProvider(
                "k1",
                "k1=" + SECRET_1 + ",k2=" + SECRET_2,
                SECRET_1, 3600000L);

        UUID userId = UUID.randomUUID();
        String token = provider.generateToken(userId, "user@example.com");

        assertNotNull(token);
        assertTrue(token.contains("eyJ")); // 有 header 段
        assertTrue(provider.validateToken(token));
        assertEquals(userId, provider.getUserIdFromToken(token));
    }

    @Test
    void tokenSignedWithOldKeyStillValidDuringRotation() {
        JwtProvider oldProvider = new JwtProvider(
                "legacy", "legacy=" + SECRET_1, SECRET_1, 3600000L);
        UUID userId = UUID.randomUUID();
        String oldToken = oldProvider.generateToken(userId, "user@example.com");

        // 轮换后：active 切到 k2，但 legacy 密钥仍在密钥表中 → 旧 Token 可验签
        JwtProvider newProvider = new JwtProvider(
                "k2",
                "k2=" + SECRET_2 + ",legacy=" + SECRET_1,
                SECRET_2, 3600000L);

        assertTrue(newProvider.validateToken(oldToken));
        assertEquals(userId, newProvider.getUserIdFromToken(oldToken));
    }

    @Test
    void tokenWithRemovedOldKeyRejectedAfterRotation() {
        JwtProvider oldProvider = new JwtProvider(
                "k1", "k1=" + SECRET_1, SECRET_1, 3600000L);
        String oldToken = oldProvider.generateToken(UUID.randomUUID(), "a@b.c");

        // 旧密钥已从密钥表移除 → 无法验签
        JwtProvider newProvider = new JwtProvider(
                "k2", "k2=" + SECRET_2, SECRET_2, 3600000L);

        assertFalse(newProvider.validateToken(oldToken));
    }

    @Test
    void singleSecretFallsBackToLegacyKid() {
        JwtProvider provider = new JwtProvider(
                "legacy", "", SECRET_1, 3600000L);
        UUID userId = UUID.randomUUID();
        String token = provider.generateToken(userId, "user@example.com");

        assertTrue(provider.validateToken(token));
        assertEquals(userId, provider.getUserIdFromToken(token));
    }
}
