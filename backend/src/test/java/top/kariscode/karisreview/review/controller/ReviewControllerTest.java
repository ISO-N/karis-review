package top.kariscode.karisreview.review.controller;

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
import top.kariscode.karisreview.review.dto.RateRequest;
import top.kariscode.karisreview.review.dto.RateResponse;
import top.kariscode.karisreview.review.dto.ReviewCardResponse;
import top.kariscode.karisreview.review.service.ReviewService;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ReviewController.class)
@Import({SecurityConfig.class, JwtAuthenticationFilter.class, JacksonConfig.class})
class ReviewControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private ReviewService reviewService;

    @MockitoBean
    private JwtProvider jwtProvider;

    @Test
    void getDueCardsReturnsQueue() throws Exception {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        when(reviewService.getDueCards(userId, deckId)).thenReturn(List.of(reviewCard()));

        mockMvc.perform(get("/api/review/due").with(authentication(userId))
                        .param("deck_id", deckId.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].front").value("正面"));
    }

    @Test
    void getNewCardsReturnsAllQueue() throws Exception {
        UUID userId = UUID.randomUUID();
        when(reviewService.getNewCards(userId, null)).thenReturn(List.of(reviewCard()));

        mockMvc.perform(get("/api/review/new").with(authentication(userId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1));
    }

    @Test
    void rateCardReturnsRatingResult() throws Exception {
        UUID userId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        RateResponse response = new RateResponse(
                cardId, "FAMILIAR", 0, 1, LocalDate.now(), false, 0, 1);
        when(reviewService.rateCard(eq(userId), eq(cardId), any(RateRequest.class)))
                .thenReturn(response);

        mockMvc.perform(post("/api/review/{cardId}/rate", cardId)
                        .with(authentication(userId))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"rating\":\"FAMILIAR\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.stage_after").value(1));
    }

    @Test
    void rateCardValidatesRating() throws Exception {
        mockMvc.perform(post("/api/review/{cardId}/rate", UUID.randomUUID())
                        .with(authentication(UUID.randomUUID()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"rating\":\"UNKNOWN\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400));
    }

    @Test
    void missingCardReturns404() throws Exception {
        UUID userId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        when(reviewService.rateCard(eq(userId), eq(cardId), any(RateRequest.class)))
                .thenThrow(new BusinessException(404, "卡片不存在"));

        mockMvc.perform(post("/api/review/{cardId}/rate", cardId)
                        .with(authentication(userId))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"rating\":\"FAMILIAR\"}"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("卡片不存在"));
    }

    private ReviewCardResponse reviewCard() {
        return new ReviewCardResponse(
                UUID.randomUUID(), UUID.randomUUID(), "正面", "反面",
                0, false, 0, 5, null, null, 0, 1, 0);
    }

    private RequestPostProcessor authentication(UUID userId) {
        return SecurityMockMvcRequestPostProcessors.authentication(
                new UsernamePasswordAuthenticationToken(userId, null, List.of()));
    }
}
