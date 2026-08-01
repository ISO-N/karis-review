package top.kariscode.karisreview.stats.controller;

import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import top.kariscode.karisreview.common.dto.ApiResponse;
import top.kariscode.karisreview.stats.dto.DeckStatsResponse;
import top.kariscode.karisreview.stats.dto.OverviewStatsResponse;
import top.kariscode.karisreview.stats.dto.TrendStatsResponse;
import top.kariscode.karisreview.stats.service.StatsService;

import java.util.List;
import java.util.UUID;

@SecurityRequirement(name = "bearerAuth")
@RestController
@RequestMapping("/api/stats")
public class StatsController {

    private final StatsService statsService;

    public StatsController(StatsService statsService) {
        this.statsService = statsService;
    }

    @GetMapping("/overview")
    public ResponseEntity<ApiResponse<OverviewStatsResponse>> getOverview(
            @AuthenticationPrincipal UUID userId) {
        OverviewStatsResponse stats = statsService.getOverview(userId);
        return ResponseEntity.ok(ApiResponse.success(stats));
    }

    @GetMapping("/deck/{deckId}")
    public ResponseEntity<ApiResponse<DeckStatsResponse>> getDeckStats(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID deckId) {
        DeckStatsResponse stats = statsService.getDeckStats(userId, deckId);
        return ResponseEntity.ok(ApiResponse.success(stats));
    }

    @GetMapping("/trend")
    public ResponseEntity<ApiResponse<List<TrendStatsResponse>>> getTrend(
            @AuthenticationPrincipal UUID userId,
            @RequestParam(defaultValue = "30") int days) {
        List<TrendStatsResponse> trend = statsService.getTrend(userId, days);
        return ResponseEntity.ok(ApiResponse.success(trend));
    }
}