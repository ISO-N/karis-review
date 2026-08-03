package top.kariscode.karisreview.deck.controller;

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
import top.kariscode.karisreview.common.etag.UserEtagService;
import top.kariscode.karisreview.config.JacksonConfig;
import top.kariscode.karisreview.config.JwtAuthenticationFilter;
import top.kariscode.karisreview.config.JwtProvider;
import top.kariscode.karisreview.config.SecurityConfig;
import top.kariscode.karisreview.deck.dto.DeckCreateRequest;
import top.kariscode.karisreview.deck.dto.DeckResponse;
import top.kariscode.karisreview.deck.dto.DeckUpdateRequest;
import top.kariscode.karisreview.deck.service.DeckService;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(DeckController.class)
@Import({SecurityConfig.class, JwtAuthenticationFilter.class, JacksonConfig.class})
class DeckControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private DeckService deckService;

    @MockitoBean
    private UserEtagService etagService;

    @MockitoBean
    private JwtProvider jwtProvider;

    @Test
    void getDecksReturnsList() throws Exception {
        UUID userId = UUID.randomUUID();
        when(deckService.getUserDecks(userId)).thenReturn(List.of(response("日语")));
        when(etagService.decksEtag(userId)).thenReturn("W/\"test-etag\"");

        mockMvc.perform(get("/api/decks").with(authentication(userId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].name").value("日语"));
    }

    @Test
    void createDeckReturnsCreatedDeck() throws Exception {
        UUID userId = UUID.randomUUID();
        when(deckService.createDeck(eq(userId), any(DeckCreateRequest.class)))
                .thenReturn(response("新牌组"));

        mockMvc.perform(post("/api/decks")
                        .with(authentication(userId))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"新牌组\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("deck.created"))
                .andExpect(jsonPath("$.data.name").value("新牌组"));
    }

    @Test
    void createDeckValidatesName() throws Exception {
        mockMvc.perform(post("/api/decks")
                        .with(authentication(UUID.randomUUID()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400));
    }

    @Test
    void updateDeckRenamesDeck() throws Exception {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        when(deckService.updateDeck(eq(userId), eq(deckId), any(DeckUpdateRequest.class)))
                .thenReturn(response("新名"));

        mockMvc.perform(put("/api/decks/{deckId}", deckId)
                        .with(authentication(userId))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"新名\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("新名"));
    }

    @Test
    void deleteDeckDeletesDeck() throws Exception {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();

        mockMvc.perform(delete("/api/decks/{deckId}", deckId)
                        .with(authentication(userId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("deck.deleted"));
    }

    @Test
    void missingDeckReturns404() throws Exception {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        doThrow(new BusinessException(404, "deck.notfound"))
                .when(deckService).deleteDeck(userId, deckId);

        mockMvc.perform(delete("/api/decks/{deckId}", deckId)
                        .with(authentication(userId)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("deck.notfound"));
    }

    private DeckResponse response(String name) {
        return new DeckResponse(
                UUID.randomUUID(), name, 1, 0, 0, 0,
                List.of(1L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L),
                List.of(0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L), LocalDateTime.now());
    }

    private RequestPostProcessor authentication(UUID userId) {
        return SecurityMockMvcRequestPostProcessors.authentication(
                new UsernamePasswordAuthenticationToken(userId, null, List.of()));
    }
}
