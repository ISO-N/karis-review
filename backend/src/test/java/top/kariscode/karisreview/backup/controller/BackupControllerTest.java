package top.kariscode.karisreview.backup.controller;

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
import top.kariscode.karisreview.backup.service.BackupService;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.config.JacksonConfig;
import top.kariscode.karisreview.config.JwtAuthenticationFilter;
import top.kariscode.karisreview.config.JwtProvider;
import top.kariscode.karisreview.config.SecurityConfig;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(BackupController.class)
@Import({SecurityConfig.class, JwtAuthenticationFilter.class, JacksonConfig.class})
class BackupControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private BackupService backupService;

    @MockitoBean
    private JwtProvider jwtProvider;

    @Test
    void exportDataReturnsSnapshot() throws Exception {
        UUID userId = UUID.randomUUID();
        when(backupService.exportData(userId)).thenReturn(
                Map.of("backup_id", UUID.randomUUID().toString(), "data", Map.of()));

        mockMvc.perform(post("/api/backup/export").with(authentication(userId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("backup.created"))
                .andExpect(jsonPath("$.data.backup_id").isString());
    }

    @Test
    void importDataRestoresSnapshot() throws Exception {
        UUID userId = UUID.randomUUID();
        when(backupService.importData(eq(userId), any(Map.class)))
                .thenReturn(Map.of("imported_decks", 1, "imported_cards", 1));

        mockMvc.perform(post("/api/backup/import")
                        .with(authentication(userId))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"data":{"decks":[]}}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("backup.imported"))
                .andExpect(jsonPath("$.data.imported_decks").value(1));
    }

    @Test
    void importDataRequiresDataField() throws Exception {
        mockMvc.perform(post("/api/backup/import")
                        .with(authentication(UUID.randomUUID()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("backup.data.empty"));
    }

    @Test
    void backupServiceErrorReturns404() throws Exception {
        UUID userId = UUID.randomUUID();
        when(backupService.exportData(userId))
                .thenThrow(new BusinessException(404, "settings.notfound"));

        mockMvc.perform(post("/api/backup/export").with(authentication(userId)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("settings.notfound"));
    }

    private RequestPostProcessor authentication(UUID userId) {
        return SecurityMockMvcRequestPostProcessors.authentication(
                new UsernamePasswordAuthenticationToken(userId, null, List.of()));
    }
}