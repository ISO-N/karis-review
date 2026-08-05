package top.kariscode.karisreview.config;

import jakarta.servlet.FilterChain;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * 限流过滤器测试（WP-6/G7）：认证接口按 IP、业务接口按用户限流，超限返回 429。
 */
class RateLimitFilterTest {

    @Test
    void authRequestLimitedByIp() throws Exception {
        RateLimitFilter filter = new RateLimitFilter(true, 2, 100);
        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = (req, res) -> {};

        MockHttpServletRequest req = new MockHttpServletRequest("POST", "/api/auth/login");
        req.setRemoteAddr("10.0.0.1");

        filter.doFilter(req, response, chain);
        filter.doFilter(req, response, chain);
        assertEquals(200, response.getStatus());

        filter.doFilter(req, response, chain);
        assertEquals(429, response.getStatus());
        assertEquals("60", response.getHeader("Retry-After"));
    }

    @Test
    void authRequestDifferentIpsHaveSeparateBuckets() throws Exception {
        RateLimitFilter filter = new RateLimitFilter(true, 1, 100);
        MockHttpServletResponse r1 = new MockHttpServletResponse();
        MockHttpServletResponse r2 = new MockHttpServletResponse();
        FilterChain chain = (req, res) -> {};

        MockHttpServletRequest req1 = new MockHttpServletRequest("POST", "/api/auth/login");
        req1.setRemoteAddr("10.0.0.1");
        MockHttpServletRequest req2 = new MockHttpServletRequest("POST", "/api/auth/login");
        req2.setRemoteAddr("10.0.0.2");

        filter.doFilter(req1, r1, chain);
        filter.doFilter(req2, r2, chain);
        assertEquals(200, r1.getStatus());
        assertEquals(200, r2.getStatus());
    }

    @Test
    void apiRequestLimitedByUser() throws Exception {
        RateLimitFilter filter = new RateLimitFilter(true, 100, 2);
        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = (req, res) -> {};

        MockHttpServletRequest req = new MockHttpServletRequest("GET", "/api/decks");
        UUID userId = UUID.randomUUID();
        req.setRemoteAddr("10.0.0.1");
        // 生产环境由 JwtAuthenticationFilter 注入 UUID principal
        org.springframework.security.authentication.UsernamePasswordAuthenticationToken auth =
                new org.springframework.security.authentication.UsernamePasswordAuthenticationToken(
                        userId, null, java.util.Collections.emptyList());
        org.springframework.security.core.context.SecurityContextHolder.getContext().setAuthentication(auth);
        try {
            filter.doFilter(req, response, chain);
            filter.doFilter(req, response, chain);
            assertEquals(200, response.getStatus());

            filter.doFilter(req, response, chain);
            assertEquals(429, response.getStatus());
            assertTrue(response.getContentAsString().contains("rate.limit"));
        } finally {
            org.springframework.security.core.context.SecurityContextHolder.clearContext();
        }
    }

    @Test
    void disabledFilterPassesEverything() throws Exception {
        RateLimitFilter filter = new RateLimitFilter(false, 1, 1);
        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = (req, res) -> {};

        MockHttpServletRequest req = new MockHttpServletRequest("POST", "/api/auth/login");
        req.setRemoteAddr("10.0.0.1");
        for (int i = 0; i < 5; i++) {
            filter.doFilter(req, response, chain);
        }
        assertEquals(200, response.getStatus());
    }
}
