package top.kariscode.karisreview.settings.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.config.JacksonConfig;
import top.kariscode.karisreview.config.JwtAuthenticationFilter;
import top.kariscode.karisreview.config.JwtProvider;
import top.kariscode.karisreview.config.SecurityConfig;
import top.kariscode.karisreview.settings.dto.UpdateSettingsRequest;
import top.kariscode.karisreview.settings.dto.UserSettingsResponse;
import top.kariscode.karisreview.settings.service.SettingsService;

import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(SettingsController.class)
@Import({SecurityConfig.class, JwtAuthenticationFilter.class, JacksonConfig.class})
class SettingsControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private SettingsService settingsService;

    @MockitoBean
    private JwtProvider jwtProvider;

    @Test
    void getSettingsReturnsSettings() throws Exception {
        UUID userId = UUID.randomUUID();
        when(settingsService.getSettings(userId))
                .thenReturn(new UserSettingsResponse("user@example.com", LocalTime.of(4, 0)));

        mockMvc.perform(get("/api/settings").with(authentication(userId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.refresh_time").value("04:00:00"));
    }

    @Test
    void updateSettingsSavesRefreshTime() throws Exception {
        UUID userId = UUID.randomUUID();
        when(settingsService.updateSettings(eq(userId), any(UpdateSettingsRequest.class)))
                .thenReturn(new UserSettingsResponse("user@example.com", LocalTime.of(3, 0)));

        mockMvc.perform(put("/api/settings")
                        .with(authentication(userId))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refresh_time\":\"03:00:00\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("settings.updated"))
                .andExpect(jsonPath("$.data.refresh_time").value("03:00:00"));
    }

    @Test
    void updateSettingsValidatesTimeFormat() throws Exception {
        mockMvc.perform(put("/api/settings")
                        .with(authentication(UUID.randomUUID()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refresh_time\":\"25:00:00\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400));
    }

    @Test
    void missingUserReturns404() throws Exception {
        UUID userId = UUID.randomUUID();
        when(settingsService.getSettings(userId))
                .thenThrow(new BusinessException(404, "settings.notfound"));

        mockMvc.perform(get("/api/settings").with(authentication(userId)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("settings.notfound"));
    }

    private RequestPostProcessor authentication(UUID userId) {
        return SecurityMockMvcRequestPostProcessors.authentication(
                new UsernamePasswordAuthenticationToken(userId, null, List.of()));
    }
}