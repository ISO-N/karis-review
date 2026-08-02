package top.kariscode.karisreview.review.controller;

import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import top.kariscode.karisreview.common.dto.ApiResponse;
import top.kariscode.karisreview.review.dto.RateRequest;
import top.kariscode.karisreview.review.dto.RateResponse;
import top.kariscode.karisreview.review.dto.ReviewCardResponse;
import top.kariscode.karisreview.review.dto.ReviewSessionCreateRequest;
import top.kariscode.karisreview.review.dto.ReviewSessionPageResponse;
import top.kariscode.karisreview.review.dto.ReviewSyncRequest;
import top.kariscode.karisreview.review.dto.ReviewSyncResponse;
import top.kariscode.karisreview.review.service.ReviewService;

import java.util.List;
import java.util.UUID;

@SecurityRequirement(name = "bearerAuth")
@RestController
@RequestMapping("/api/review")
public class ReviewController {

    private final ReviewService reviewService;

    public ReviewController(ReviewService reviewService) {
        this.reviewService = reviewService;
    }

    @GetMapping("/due")
    public ResponseEntity<ApiResponse<List<ReviewCardResponse>>> getDueCards(
            @AuthenticationPrincipal UUID userId,
            @RequestParam(name = "deck_id", required = false) UUID deckId,
            @RequestParam(defaultValue = "500") int limit) {
        List<ReviewCardResponse> cards = reviewService.getDueCards(userId, deckId, limit);
        return ResponseEntity.ok(ApiResponse.success(cards));
    }

    @GetMapping("/new")
    public ResponseEntity<ApiResponse<List<ReviewCardResponse>>> getNewCards(
            @AuthenticationPrincipal UUID userId,
            @RequestParam(name = "deck_id", required = false) UUID deckId,
            @RequestParam(defaultValue = "10") int limit) {
        List<ReviewCardResponse> cards = reviewService.getNewCards(userId, deckId, limit);
        return ResponseEntity.ok(ApiResponse.success(cards));
    }

    @PostMapping("/sessions")
    public ResponseEntity<ApiResponse<ReviewSessionPageResponse>> createSession(
            @AuthenticationPrincipal UUID userId,
            @Valid @RequestBody ReviewSessionCreateRequest request) {
        ReviewSessionPageResponse response = reviewService.createSession(userId, request);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @GetMapping("/sessions/{sessionId}")
    public ResponseEntity<ApiResponse<ReviewSessionPageResponse>> getSessionPage(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID sessionId,
            @RequestParam(defaultValue = "0") int cursor,
            @RequestParam(defaultValue = "10") int limit) {
        ReviewSessionPageResponse response = reviewService.getSessionPage(
                userId, sessionId, cursor, limit);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @DeleteMapping("/sessions/{sessionId}")
    public ResponseEntity<ApiResponse<Void>> deleteSession(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID sessionId) {
        reviewService.deleteSession(userId, sessionId);
        return ResponseEntity.ok(ApiResponse.success("复习会话已关闭", null));
    }

    @PostMapping("/sync")
    public ResponseEntity<ApiResponse<ReviewSyncResponse>> syncRatings(
            @AuthenticationPrincipal UUID userId,
            @Valid @RequestBody ReviewSyncRequest request) {
        ReviewSyncResponse response = reviewService.syncRatings(userId, request);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @PostMapping("/{cardId}/rate")
    public ResponseEntity<ApiResponse<RateResponse>> rateCard(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID cardId,
            @Valid @RequestBody RateRequest request) {
        RateResponse response = reviewService.rateCard(userId, cardId, request);
        return ResponseEntity.ok(ApiResponse.success(response));
    }
}
