package top.kariscode.karisreview.config;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class InviteCodeConfigTest {

    @Test
    void enabledConfigRequiresNonBlankCode() {
        IllegalStateException exception = assertThrows(
                IllegalStateException.class, () -> new InviteCodeConfig(true, "  "));

        assertEquals("auth.invite.code must not be empty when auth.invite.enabled=true", exception.getMessage());
    }

    @Test
    void matchesTrimsCandidateAndConfiguredCode() {
        InviteCodeConfig config = new InviteCodeConfig(true, " test-code ");

        assertTrue(config.matches("test-code"));
        assertTrue(config.matches("  test-code  "));
        assertFalse(config.matches("wrong-code"));
        assertFalse(config.matches(""));
        assertFalse(config.matches(null));
    }

    @Test
    void disabledConfigIsReported() {
        InviteCodeConfig config = new InviteCodeConfig(false, "");

        assertFalse(config.isEnabled());
        assertTrue(config.matches(""));
        assertFalse(config.matches("any-code"));
    }
}
