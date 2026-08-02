package top.kariscode.karisreview.sync.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;
import top.kariscode.karisreview.config.JacksonConfig;
import top.kariscode.karisreview.config.JwtAuthenticationFilter;
import top.kariscode.karisreview.config.JwtProvider;
import top.kariscode.karisreview.config.SecurityConfig;
import top.kariscode.karisreview.sync.dto.BootstrapResponse;
import top.kariscode.karisreview.sync.dto.BootstrapReviewLog;
import top.kariscode.karisreview.sync.dto.BootstrapUser;
import top.kariscode.karisreview.sync.service.SyncProtoMapper;
import top.kariscode.karisreview.sync.service.SyncService;

import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(SyncController.class)
@Import({SecurityConfig.class, JwtAuthenticationFilter.class, JacksonConfig.class})
class SyncControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private SyncService syncService;

    @MockitoBean
    private SyncProtoMapper syncProtoMapper;

    @MockitoBean
    private JwtProvider jwtProvider;

    @Test
    void bootstrapReturnsOfflineSnapshot() throws Exception {
        UUID userId = UUID.randomUUID();
        BootstrapReviewLog log = new BootstrapReviewLog(
                UUID.randomUUID(), UUID.randomUUID(), "FAMILIAR",
                0, 1, LocalDateTime.of(2025, 8, 2, 12, 0), true);
        BootstrapResponse response = new BootstrapResponse(
                OffsetDateTime.now(ZoneOffset.UTC),
                new BootstrapUser(userId, "a@b.c", "04:00:00"),
                List.of(),
                List.of(log));
        when(syncService.getBootstrap(eq(userId), eq(0L))).thenReturn(response);

        mockMvc.perform(get("/api/sync/bootstrap").with(authentication(userId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.user.email").value("a@b.c"))
                .andExpect(jsonPath("$.data.decks.length()").value(0))
                .andExpect(jsonPath("$.data.review_logs[0].is_new_card").value(true));
    }

    private RequestPostProcessor authentication(UUID userId) {
        return SecurityMockMvcRequestPostProcessors.authentication(
                new UsernamePasswordAuthenticationToken(userId, null, List.of()));
    }
}
