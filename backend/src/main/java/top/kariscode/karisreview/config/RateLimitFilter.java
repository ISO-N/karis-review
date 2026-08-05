package top.kariscode.karisreview.config;

import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
import io.github.bucket4j.Refill;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.Duration;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 限流过滤器（WP-6/G7）：
 * <ul>
 *   <li>认证类接口（/api/auth/** 与 /api/backup/import 等高危接口）按 <b>IP</b> 限流；</li>
 *   <li>通用业务接口按 <b>用户</b> 限流；</li>
 *   <li>超限返回 429 + Retry-After 头。</li>
 * </ul>
 * 使用 Bucket4j 内存令牌桶，单实例部署足够；多实例部署时可在网关层叠加 IP 限流。
 */
@Component
public class RateLimitFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(RateLimitFilter.class);

    private static final String AUTH_PREFIX = "/api/auth/";
    private static final String BACKUP_IMPORT = "/api/backup/import";

    private final boolean enabled;
    private final int authPerMinute;
    private final int apiPerMinute;
    private final Map<String, Bucket> buckets = new ConcurrentHashMap<>();

    public RateLimitFilter(@Value("${app.rate-limit.enabled:true}") boolean enabled,
                           @Value("${app.rate-limit.auth.per-minute:20}") int authPerMinute,
                           @Value("${app.rate-limit.api.per-minute:120}") int apiPerMinute) {
        this.enabled = enabled;
        this.authPerMinute = authPerMinute;
        this.apiPerMinute = apiPerMinute;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !enabled;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        if (isAuthRequest(request)) {
            // 认证接口：按 IP 限流（登录/注册/发码防爆破）
            String ip = clientIp(request);
            if (!allow(ip, authPerMinute)) {
                reject(response, ip);
                return;
            }
        } else if (isProtectedApi(request)) {
            // 业务接口：按用户限流
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth != null && auth.getPrincipal() instanceof UUID userId) {
                if (!allow("user:" + userId, apiPerMinute)) {
                    reject(response, userId.toString());
                    return;
                }
            }
        }
        filterChain.doFilter(request, response);
    }

    private boolean isAuthRequest(HttpServletRequest request) {
        String uri = request.getRequestURI();
        return uri.startsWith(AUTH_PREFIX) || uri.equals(BACKUP_IMPORT);
    }

    private boolean isProtectedApi(HttpServletRequest request) {
        return request.getRequestURI().startsWith("/api/");
    }

    private boolean allow(String key, int perMinute) {
        Bucket bucket = buckets.computeIfAbsent(key, k -> Bucket.builder()
                .addLimit(Bandwidth.classic(perMinute, Refill.greedy(perMinute, Duration.ofMinutes(1))))
                .build());
        return bucket.tryConsume(1);
    }

    private void reject(HttpServletResponse response, String subject) throws IOException {
        log.warn("Rate limit exceeded for {}", subject);
        response.setStatus(429);
        response.setHeader("Retry-After", "60");
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write("{\"code\":429,\"message\":\"rate.limit.exceeded\",\"data\":null}");
    }

    private String clientIp(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            return forwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
