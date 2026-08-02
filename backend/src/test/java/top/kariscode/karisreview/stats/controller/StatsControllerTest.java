package top.kariscode.karisreview.stats.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
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
import top.kariscode.karisreview.stats.dto.DeckStatsResponse;
import top.kariscode.karisreview.stats.dto.OverviewStatsResponse;
import top.kariscode.karisreview.stats.dto.TrendStatsResponse;
import top.kariscode.karisreview.stats.service.StatsService;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(StatsController.class)
@Import({SecurityConfig.class, JwtAuthenticationFilter.class, JacksonConfig.class})
class StatsControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private StatsService statsService;

    @MockitoBean
    private UserEtagService etagService;

    @MockitoBean
    private JwtProvider jwtProvider;

    @Test
    void getOverviewReturnsStats() throws Exception {
        UUID userId = UUID.randomUUID();
        OverviewStatsResponse stats = new OverviewStatsResponse();
        stats.setTotalCards(10);
        stats.setTotalDecks(2);
        stats.setStageDistribution(List.of(10L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L));
        stats.setDueStageDistribution(List.of(1L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L));
        when(statsService.getOverview(userId)).thenReturn(stats);
        when(etagService.overviewEtag(userId)).thenReturn("W/\"test-etag\"");
        mockMvc.perform(get("/api/stats/overview").with(authentication(userId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total_cards").value(10))
                .andExpect(jsonPath("$.data.total_decks").value(2));
    }

    @Test
    void getDeckStatsReturnsDeckStats() throws Exception {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        DeckStatsResponse stats = new DeckStatsResponse();
        stats.setDeckId(deckId.toString());
        stats.setDeckName("日语");
        stats.setTotalCards(5);
        stats.setStageDistribution(List.of(5L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L));
        stats.setDueStageDistribution(List.of(0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L));
        when(statsService.getDeckStats(userId, deckId)).thenReturn(stats);
        when(etagService.deckStatsEtag(userId, deckId)).thenReturn("W/\"test-etag\"");

        mockMvc.perform(get("/api/stats/deck/{deckId}", deckId)
                        .with(authentication(userId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.deck_name").value("日语"));
    }

    @Test
    void getTrendReturnsTrendRows() throws Exception {
        UUID userId = UUID.randomUUID();
        when(statsService.getTrend(userId, 7))
                .thenReturn(List.of(new TrendStatsResponse(LocalDate.of(2025, 1, 1), 3, 1)));

        mockMvc.perform(get("/api/stats/trend").with(authentication(userId))
                        .param("days", "7"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].reviewed").value(3));
    }

    @Test
    void missingDeckReturns404() throws Exception {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        when(statsService.getDeckStats(userId, deckId))
                .thenThrow(new BusinessException(404, "牌组不存在"));

        mockMvc.perform(get("/api/stats/deck/{deckId}", deckId)
                        .with(authentication(userId)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("牌组不存在"));
    }

    private RequestPostProcessor authentication(UUID userId) {
        return SecurityMockMvcRequestPostProcessors.authentication(
                new UsernamePasswordAuthenticationToken(userId, null, List.of()));
    }
}
