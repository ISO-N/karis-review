package top.kariscode.karisreview.card.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.data.domain.PageImpl;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;
import top.kariscode.karisreview.card.dto.CardBatchDeleteRequest;
import top.kariscode.karisreview.card.dto.CardCreateRequest;
import top.kariscode.karisreview.card.dto.CardResponse;
import top.kariscode.karisreview.card.dto.CardUpdateRequest;
import top.kariscode.karisreview.card.service.CardService;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.config.JacksonConfig;
import top.kariscode.karisreview.config.JwtAuthenticationFilter;
import top.kariscode.karisreview.config.JwtProvider;
import top.kariscode.karisreview.config.SecurityConfig;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(CardController.class)
@Import({SecurityConfig.class, JwtAuthenticationFilter.class, JacksonConfig.class})
class CardControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private CardService cardService;

    @MockitoBean
    private JwtProvider jwtProvider;

    @Test
    void getCardsReturnsPagedResponse() throws Exception {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        when(cardService.getDeckCards(userId, deckId, 0, 20, "all", ""))
                .thenReturn(new PageImpl<>(List.of(response("正面", "反面"))));

        mockMvc.perform(get("/api/decks/{deckId}/cards", deckId)
                        .with(authentication(userId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content[0].front").value("正面"))
                .andExpect(jsonPath("$.data.total_elements").value(1));
    }

    @Test
    void getCardsPassesSearchQuery() throws Exception {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        when(cardService.getDeckCards(userId, deckId, 0, 20, "all", "词"))
                .thenReturn(new PageImpl<>(List.of(response("命中词", "反面"))));

        mockMvc.perform(get("/api/decks/{deckId}/cards", deckId)
                        .with(authentication(userId))
                        .param("q", "词"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content[0].front").value("命中词"));
    }

    @Test
    void createCardReturnsCard() throws Exception {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        when(cardService.createCard(eq(userId), eq(deckId), any(CardCreateRequest.class)))
                .thenReturn(response("正面", "反面"));

        mockMvc.perform(post("/api/decks/{deckId}/cards", deckId)
                        .with(authentication(userId))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"front\":\"正面\",\"back\":\"反面\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("card.created"))
                .andExpect(jsonPath("$.data.front").value("正面"));
    }

    @Test
    void createCardValidatesContent() throws Exception {
        mockMvc.perform(post("/api/decks/{deckId}/cards", UUID.randomUUID())
                        .with(authentication(UUID.randomUUID()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"front\":\"\",\"back\":\"\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400));
    }

    @Test
    void getCardReturnsSingleCard() throws Exception {
        UUID userId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        when(cardService.getCard(userId, cardId)).thenReturn(response("正面", "反面"));

        mockMvc.perform(get("/api/cards/{cardId}", cardId)
                        .with(authentication(userId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(responseId().toString()));
    }

    @Test
    void updateCardReturnsUpdatedCard() throws Exception {
        UUID userId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        when(cardService.updateCard(eq(userId), eq(cardId), any(CardUpdateRequest.class)))
                .thenReturn(response("新正面", "新反面"));

        mockMvc.perform(put("/api/cards/{cardId}", cardId)
                        .with(authentication(userId))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"front\":\"新正面\",\"back\":\"新反面\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("card.updated"));
    }

    @Test
    void deleteCardDeletesCard() throws Exception {
        UUID userId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();

        mockMvc.perform(delete("/api/cards/{cardId}", cardId)
                        .with(authentication(userId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("card.deleted"));
    }

    @Test
    void batchDeleteCardsDeletesOwnedCards() throws Exception {
        UUID userId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        when(cardService.deleteCards(eq(userId), anyList())).thenReturn(1);

        mockMvc.perform(post("/api/cards/batch-delete")
                        .with(authentication(userId))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"card_ids\":[\"" + cardId + "\"]}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("card.batch.deleted"))
                .andExpect(jsonPath("$.data.deleted_cards").value(1));
    }

    @Test
    void batchDeleteCardsValidatesEmptyIds() throws Exception {
        mockMvc.perform(post("/api/cards/batch-delete")
                        .with(authentication(UUID.randomUUID()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"card_ids\":[]}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400));
    }

    @Test
    void missingCardReturns404() throws Exception {
        UUID userId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        doThrow(new BusinessException(404, "card.notfound"))
                .when(cardService).deleteCard(userId, cardId);

        mockMvc.perform(delete("/api/cards/{cardId}", cardId)
                        .with(authentication(userId)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("card.notfound"));
    }

    private CardResponse response(String front, String back) {
        UUID id = responseId();
        return new CardResponse(
                id, UUID.randomUUID(), front, back, 0, null, false,
                0, 0, null, false, LocalDateTime.now());
    }

    private UUID responseId() {
        return UUID.fromString("00000000-0000-0000-0000-000000000001");
    }

    private RequestPostProcessor authentication(UUID userId) {
        return SecurityMockMvcRequestPostProcessors.authentication(
                new UsernamePasswordAuthenticationToken(userId, null, List.of()));
    }
}