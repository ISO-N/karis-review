package top.kariscode.karisreview.config;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class JwtProviderTest {

    private static final String SECRET =
            "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";

    private JwtProvider provider;

    @BeforeEach
    void setUp() {
        provider = new JwtProvider(SECRET, 604800000L);
    }

    @Test
    void generatesTokenThatCanBeParsedBack() {
        UUID userId = UUID.randomUUID();
        String email = "user@example.com";

        String token = provider.generateToken(userId, email);

        assertNotNull(token);
        assertTrue(provider.validateToken(token));
        assertEquals(userId, provider.getUserIdFromToken(token));
    }

    @Test
    void rejectsExpiredToken() {
        JwtProvider expiredProvider = new JwtProvider(SECRET, -1000L);
        String token = expiredProvider.generateToken(UUID.randomUUID(), "user@example.com");

        assertFalse(expiredProvider.validateToken(token));
    }

    @Test
    void rejectsTamperedToken() {
        String token = provider.generateToken(UUID.randomUUID(), "user@example.com");
        char last = token.charAt(token.length() - 1);
        String tampered = token.substring(0, token.length() - 1)
                + (last == 'a' ? 'b' : 'a');

        assertFalse(provider.validateToken(tampered));
    }

    @Test
    void rejectsMalformedToken() {
        assertFalse(provider.validateToken("not-a-jwt"));
    }
}
