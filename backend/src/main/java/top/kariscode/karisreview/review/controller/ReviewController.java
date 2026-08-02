package top.kariscode.karisreview.review.controller;

import jakarta.validation.Valid;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import top.kariscode.karisreview.common.dto.ApiResponse;
import top.kariscode.karisreview.review.dto.RateRequest;
import top.kariscode.karisreview.review.dto.RateResponse;
import top.kariscode.karisreview.review.dto.ReviewCardResponse;
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
            @RequestParam(name = "deck_id", required = false) UUID deckId) {
        List<ReviewCardResponse> cards = reviewService.getDueCards(userId, deckId);
        return ResponseEntity.ok(ApiResponse.success(cards));
    }

    @GetMapping("/new")
    public ResponseEntity<ApiResponse<List<ReviewCardResponse>>> getNewCards(
            @AuthenticationPrincipal UUID userId,
            @RequestParam(name = "deck_id", required = false) UUID deckId) {
        List<ReviewCardResponse> cards = reviewService.getNewCards(userId, deckId);
        return ResponseEntity.ok(ApiResponse.success(cards));
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