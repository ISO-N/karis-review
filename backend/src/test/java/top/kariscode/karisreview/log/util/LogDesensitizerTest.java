package top.kariscode.karisreview.log.util;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class LogDesensitizerTest {

    @Test
    void nullMessageBecomesEmptyString() {
        assertEquals("", LogDesensitizer.desensitize(null));
    }

    @Test
    void emailAddressesAreReplaced() {
        String result = LogDesensitizer.desensitize("user@example.com logged in");

        assertFalse(result.contains("user@example.com"));
        assertTrue(result.contains("[EMAIL]"));
    }

    @Test
    void longMessageIsTruncated() {
        String result = LogDesensitizer.desensitize("a".repeat(700));

        assertEquals(503, result.length());
        assertTrue(result.startsWith("a".repeat(500)));
        assertTrue(result.endsWith("..."));
    }
}
