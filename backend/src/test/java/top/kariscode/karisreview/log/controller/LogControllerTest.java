package top.kariscode.karisreview.log.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;
import top.kariscode.karisreview.config.JacksonConfig;
import top.kariscode.karisreview.config.JwtAuthenticationFilter;
import top.kariscode.karisreview.config.JwtProvider;
import top.kariscode.karisreview.config.SecurityConfig;
import top.kariscode.karisreview.log.dto.UserLogResponse;
import top.kariscode.karisreview.log.service.UserLogService;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(LogController.class)
@Import({SecurityConfig.class, JwtAuthenticationFilter.class, JacksonConfig.class})
class LogControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private UserLogService userLogService;

    @MockitoBean
    private JwtProvider jwtProvider;

    @Test
    void getLogsReturnsDefaultPage() throws Exception {
        UUID userId = UUID.randomUUID();
        UserLogResponse log = new UserLogResponse(
                UUID.randomUUID(), "INFO", "AUTH", "Registration successful",
                null, LocalDateTime.of(2025, 8, 2, 12, 0));
        when(userLogService.getLogs(eq(userId), isNull(), isNull(), eq(0), eq(50)))
                .thenReturn(new PageImpl<>(List.of(log), PageRequest.of(0, 50), 1));
        mockMvc.perform(get("/api/logs").with(authentication(userId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content[0].level").value("INFO"))
                .andExpect(jsonPath("$.data.content[0].category").value("AUTH"))
                .andExpect(jsonPath("$.data.total_pages").value(1));
    }

    @Test
    void getLogsPassesFilters() throws Exception {
        UUID userId = UUID.randomUUID();
        when(userLogService.getLogs(eq(userId), eq("ERROR"), eq("SYNC"), eq(1), eq(20)))
                .thenReturn(new PageImpl<>(List.of(), PageRequest.of(0, 20), 0));

        mockMvc.perform(get("/api/logs")
                        .with(authentication(userId))
                        .param("page", "1")
                        .param("size", "20")
                        .param("level", "ERROR")
                        .param("category", "SYNC"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content.length()").value(0));
    }

    @Test
    void getLogsRequiresAuthentication() throws Exception {
        mockMvc.perform(get("/api/logs"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));
    }

    private RequestPostProcessor authentication(UUID userId) {
        return SecurityMockMvcRequestPostProcessors.authentication(
                new UsernamePasswordAuthenticationToken(userId, null, List.of()));
    }
}
