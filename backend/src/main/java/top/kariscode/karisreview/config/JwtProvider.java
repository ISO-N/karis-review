package top.kariscode.karisreview.config;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

/**
 * JWT 签发/校验（WP-8 多密钥轮换版）。
 *
 * <p>支持多个密钥按 kid 标识：签发使用 {@code jwt.active-kid} 指定的密钥，
 * 验签时按 Token header 的 kid 选择对应密钥；未知 kid 回退旧密钥（兼容滚动期）。
 *
 * <p>密钥来源：
 * <ul>
 *   <li>{@code jwt.keys.<kid>=<secret>} — 多密钥配置（推荐）；</li>
 *   <li>{@code jwt.secret} — 单密钥兼容配置（kid 固定为 legacy）。</li>
 * </ul>
 */
@Component
public class JwtProvider {

    private final Map<String, SecretKey> keys;
    private final String activeKid;
    private final long expirationMs;

    @org.springframework.beans.factory.annotation.Autowired
    public JwtProvider(
            @Value("${jwt.active-kid:legacy}") String activeKid,
            @Value("${jwt.keys:}") String keysConfig,
            @Value("${jwt.secret}") String legacySecret,
            @Value("${jwt.expiration}") long expirationMs) {
        this.activeKid = activeKid;
        this.expirationMs = expirationMs;
        this.keys = new LinkedHashMap<>();

        // 解析逗号分隔的 "kid=secret" 列表（多密钥轮换）；未配置时回退 jwt.secret 作为 legacy 单密钥
        boolean hasConfigured = false;
        if (keysConfig != null && !keysConfig.isBlank()) {
            for (String entry : keysConfig.split(",")) {
                String trimmed = entry.trim();
                if (trimmed.isEmpty()) {
                    continue;
                }
                int eq = trimmed.indexOf('=');
                if (eq <= 0 || eq == trimmed.length() - 1) {
                    continue;
                }
                String kid = trimmed.substring(0, eq).trim();
                String secret = trimmed.substring(eq + 1).trim();
                if (!kid.isEmpty() && !secret.isEmpty()) {
                    keys.put(kid, Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8)));
                    hasConfigured = true;
                }
            }
        }
        if (!hasConfigured) {
            keys.put("legacy", Keys.hmacShaKeyFor(legacySecret.getBytes(StandardCharsets.UTF_8)));
        } else if (!keys.containsKey(activeKid)) {
            // 显式密钥未包含 active kid：用 legacy 补位保证签发可用
            keys.put(activeKid, Keys.hmacShaKeyFor(legacySecret.getBytes(StandardCharsets.UTF_8)));
        }
    }

    /** 兼容单密钥构造（测试/旧配置）。 */
    public JwtProvider(String secret, long expirationMs) {
        this("legacy", "", secret, expirationMs);
    }

    public String generateToken(UUID userId, String email) {
        Date now = new Date();
        Date expiry = new Date(now.getTime() + expirationMs);

        return Jwts.builder()
                .header().keyId(activeKid).and()
                .subject(userId.toString())
                .claim("email", email)
                .issuedAt(now)
                .expiration(expiry)
                .signWith(keys.get(activeKid))
                .compact();
    }

    public UUID getUserIdFromToken(String token) {
        Claims claims = parseToken(token);
        return UUID.fromString(claims.getSubject());
    }

    public boolean validateToken(String token) {
        try {
            parseToken(token);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    private Claims parseToken(String token) {
        // 尝试按 kid 匹配密钥；未知 kid 时逐个密钥尝试（兼容滚动期旧 Token）
        String kid = readKid(token);
        SecretKey candidate = kid != null ? keys.get(kid) : null;
        if (candidate != null) {
            try {
                return parseWith(token, candidate);
            } catch (Exception ignored) {
                // kid 匹配但验签失败（如密钥被轮换），继续尝试其他密钥
            }
        }
        for (SecretKey key : keys.values()) {
            try {
                return parseWith(token, key);
            } catch (Exception ignored) {
                // continue
            }
        }
        throw new IllegalArgumentException("Invalid JWT token");
    }

    private Claims parseWith(String token, SecretKey key) {
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    private String readKid(String token) {
        try {
            String headerPart = token.split("\\.")[0];
            byte[] decoded = java.util.Base64.getUrlDecoder().decode(headerPart);
            String headerJson = new String(decoded, StandardCharsets.UTF_8);
            // {"alg":"HS256","kid":"legacy"} — 简单 JSON 解析提取 kid
            int idx = headerJson.indexOf("\"kid\"");
            if (idx < 0) {
                return null;
            }
            int colon = headerJson.indexOf(':', idx);
            int start = headerJson.indexOf('"', colon + 1);
            int end = headerJson.indexOf('"', start + 1);
            return start >= 0 && end > start ? headerJson.substring(start + 1, end) : null;
        } catch (Exception e) {
            return null;
        }
    }
}
