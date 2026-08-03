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
import top.kariscode.karisreview.config.ProtobufHttpMessageConverter;
import top.kariscode.karisreview.config.SecurityConfig;
import top.kariscode.karisreview.proto.KarisReviewProto;
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

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(SyncController.class)
@Import({SecurityConfig.class, JwtAuthenticationFilter.class, JacksonConfig.class,
        ProtobufHttpMessageConverter.class})
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
                0, 1, LocalDateTime.of(2025, 8, 2, 12, 0), true,
                "request-1");
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
                .andExpect(jsonPath("$.data.review_logs[0].is_new_card").value(true))
                .andExpect(jsonPath("$.data.review_logs[0].client_request_id").value("request-1"));
    }

    @Test
    void bootstrapPassesEventCursor() throws Exception {
        UUID userId = UUID.randomUUID();
        BootstrapResponse response = new BootstrapResponse(
                OffsetDateTime.now(ZoneOffset.UTC),
                new BootstrapUser(userId, "a@b.c", "04:00:00"),
                List.of(), List.of());
        when(syncService.getBootstrap(eq(userId), eq(7L))).thenReturn(response);

        mockMvc.perform(get("/api/sync/bootstrap")
                        .with(authentication(userId))
                        .param("event_cursor", "7"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.user.email").value("a@b.c"));
    }

    @Test
    void bootstrapReturnsProtobufWhenAccepted() throws Exception {
        UUID userId = UUID.randomUUID();
        BootstrapResponse response = new BootstrapResponse(
                OffsetDateTime.now(ZoneOffset.UTC),
                new BootstrapUser(userId, "a@b.c", "04:00:00"),
                List.of(), List.of());
        KarisReviewProto.SyncResponse proto = KarisReviewProto.SyncResponse.newBuilder()
                .setServerTime("2025-08-02T12:00:00Z")
                .setUser(KarisReviewProto.User.newBuilder()
                        .setId(userId.toString())
                        .setEmail("a@b.c")
                        .setRefreshTime("04:00:00"))
                .setEventCursor(7)
                .setResetRequired(true)
                .build();
        when(syncService.getBootstrap(eq(userId), eq(7L))).thenReturn(response);
        when(syncProtoMapper.toProto(any(BootstrapResponse.class))).thenReturn(proto);

        byte[] body = mockMvc.perform(get("/api/sync/bootstrap")
                        .with(authentication(userId))
                        .param("event_cursor", "7")
                        .header("Accept", "application/x-protobuf"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsByteArray();

        KarisReviewProto.SyncResponse parsed = KarisReviewProto.SyncResponse.parseFrom(body);
        assertEquals(7L, parsed.getEventCursor());
        assertTrue(parsed.getResetRequired());
    }

    private RequestPostProcessor authentication(UUID userId) {
        return SecurityMockMvcRequestPostProcessors.authentication(
                new UsernamePasswordAuthenticationToken(userId, null, List.of()));
    }
}
