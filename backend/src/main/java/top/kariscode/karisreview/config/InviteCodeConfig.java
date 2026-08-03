package top.kariscode.karisreview.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

@Component
public class InviteCodeConfig {

    private final boolean enabled;
    private final String code;

    public InviteCodeConfig(@Value("${auth.invite.enabled:false}") boolean enabled,
                            @Value("${auth.invite.code:}") String code) {
        this.enabled = enabled;
        this.code = code == null ? "" : code.trim();
        if (this.enabled && this.code.isEmpty()) {
            throw new IllegalStateException("auth.invite.code must not be empty when auth.invite.enabled=true");
        }
    }

    public boolean isEnabled() {
        return enabled;
    }

    public boolean matches(String candidate) {
        String actual = candidate == null ? "" : candidate.trim();
        byte[] expectedBytes = code.getBytes(StandardCharsets.UTF_8);
        byte[] actualBytes = actual.getBytes(StandardCharsets.UTF_8);
        return MessageDigest.isEqual(expectedBytes, actualBytes);
    }
}
