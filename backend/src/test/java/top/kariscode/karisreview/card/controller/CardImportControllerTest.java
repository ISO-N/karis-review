package top.kariscode.karisreview.card.controller;

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
import top.kariscode.karisreview.card.dto.CardImportPreviewItem;
import top.kariscode.karisreview.card.dto.CardImportPreviewResponse;
import top.kariscode.karisreview.card.dto.CardImportRequest;
import top.kariscode.karisreview.card.dto.CardImportResult;
import top.kariscode.karisreview.card.service.CardImportService;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.config.JacksonConfig;
import top.kariscode.karisreview.config.JwtAuthenticationFilter;
import top.kariscode.karisreview.config.JwtProvider;
import top.kariscode.karisreview.config.SecurityConfig;

import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(CardImportController.class)
@Import({SecurityConfig.class, JwtAuthenticationFilter.class, JacksonConfig.class})
class CardImportControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private CardImportService cardImportService;

    @MockitoBean
    private JwtProvider jwtProvider;

    @Test
    void previewParsesContent() throws Exception {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        CardImportPreviewResponse response = new CardImportPreviewResponse(
                1, 1, 0, List.of(new CardImportPreviewItem(0, "正面", "反面", true, null)));
        when(cardImportService.preview(userId, deckId, "content")).thenReturn(response);

        mockMvc.perform(post("/api/decks/{deckId}/cards/import/preview", deckId)
                        .with(authentication(userId))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"content\":\"content\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("解析完成"))
                .andExpect(jsonPath("$.data.cards[0].front").value("正面"));
    }

    @Test
    void importCardsReturnsCount() throws Exception {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        when(cardImportService.importCards(eq(userId), eq(deckId), any(CardImportRequest.class)))
                .thenReturn(new CardImportResult(2));

        mockMvc.perform(post("/api/decks/{deckId}/cards/import", deckId)
                        .with(authentication(userId))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"cards":[{"front":"a","back":"b"},{"front":"c","back":"d"}]}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("卡片已导入"))
                .andExpect(jsonPath("$.data.imported_cards").value(2));
    }

    @Test
    void importCardsValidatesEmptyList() throws Exception {
        mockMvc.perform(post("/api/decks/{deckId}/cards/import", UUID.randomUUID())
                        .with(authentication(UUID.randomUUID()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"cards\":[]}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400));
    }

    @Test
    void missingDeckReturns404() throws Exception {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        when(cardImportService.preview(userId, deckId, "[]"))
                .thenThrow(new BusinessException(404, "牌组不存在"));

        mockMvc.perform(post("/api/decks/{deckId}/cards/import/preview", deckId)
                        .with(authentication(userId))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"content\":\"[]\"}"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("牌组不存在"));
    }

    private RequestPostProcessor authentication(UUID userId) {
        return SecurityMockMvcRequestPostProcessors.authentication(
                new UsernamePasswordAuthenticationToken(userId, null, List.of()));
    }
}
