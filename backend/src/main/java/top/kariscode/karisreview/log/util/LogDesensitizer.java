package top.kariscode.karisreview.log.util;

import java.util.regex.Pattern;

/**
 * Desensitizes log messages to remove personally identifiable information (PII)
 * before persisting to user_logs.
 *
 * Currently handles:
 * - Email addresses → [EMAIL]
 * - Overly long text truncation (preserving structural info)
 */
public final class LogDesensitizer {

    private static final Pattern EMAIL_PATTERN =
            Pattern.compile("[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}");

    private static final int MAX_MESSAGE_LENGTH = 500;

    private LogDesensitizer() {}

    /**
     * Desensitize a log message by stripping PII and truncating if necessary.
     */
    public static String desensitize(String message) {
        if (message == null) {
            return "";
        }
        String result = message;
        // Replace email addresses
        result = EMAIL_PATTERN.matcher(result).replaceAll("[EMAIL]");
        // Truncate overly long messages
        if (result.length() > MAX_MESSAGE_LENGTH) {
            result = result.substring(0, MAX_MESSAGE_LENGTH) + "...";
        }
        return result;
    }
}