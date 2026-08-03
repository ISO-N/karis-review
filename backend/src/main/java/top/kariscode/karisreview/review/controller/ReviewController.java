package top.kariscode.karisreview.review.controller;

import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import jakarta.validation.Valid;
import org.springframework.http.MediaType;
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
import top.kariscode.karisreview.config.ProtobufHttpMessageConverter;
import top.kariscode.karisreview.proto.KarisReviewProto;
import top.kariscode.karisreview.review.dto.RateRequest;
import top.kariscode.karisreview.review.dto.RateResponse;
import top.kariscode.karisreview.review.dto.ReviewCardResponse;
import top.kariscode.karisreview.review.dto.ReviewSessionCreateRequest;
import top.kariscode.karisreview.review.dto.ReviewSessionPageResponse;
import top.kariscode.karisreview.review.dto.ReviewSyncRequest;
import top.kariscode.karisreview.review.dto.ReviewSyncResponse;
import top.kariscode.karisreview.review.service.ReviewProtoMapper;
import top.kariscode.karisreview.review.service.ReviewService;

import java.util.List;
import java.util.UUID;

@SecurityRequirement(name = "bearerAuth")
@RestController
@RequestMapping("/api/review")
public class ReviewController {

    private final ReviewService reviewService;
    private final ReviewProtoMapper protoMapper;

    public ReviewController(ReviewService reviewService, ReviewProtoMapper protoMapper) {
        this.reviewService = reviewService;
        this.protoMapper = protoMapper;
    }

    @GetMapping(value = "/due", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<List<ReviewCardResponse>>> getDueCards(
            @AuthenticationPrincipal UUID userId,
            @RequestParam(name = "deck_id", required = false) UUID deckId,
            @RequestParam(defaultValue = "500") int limit) {
        List<ReviewCardResponse> cards = reviewService.getDueCards(userId, deckId, limit);
        return ResponseEntity.ok(ApiResponse.success(cards));
    }

    @GetMapping(value = "/due", produces = ProtobufHttpMessageConverter.APPLICATION_X_PROTOBUF_VALUE)
    public ResponseEntity<KarisReviewProto.ReviewCardListResponse> getDueCardsProto(
            @AuthenticationPrincipal UUID userId,
            @RequestParam(name = "deck_id", required = false) UUID deckId,
            @RequestParam(defaultValue = "500") int limit) {
        List<ReviewCardResponse> cards = reviewService.getDueCards(userId, deckId, limit);
        return ResponseEntity.ok(protoMapper.toCardList(cards));
    }

    @GetMapping(value = "/new", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<List<ReviewCardResponse>>> getNewCards(
            @AuthenticationPrincipal UUID userId,
            @RequestParam(name = "deck_id", required = false) UUID deckId,
            @RequestParam(defaultValue = "10") int limit) {
        List<ReviewCardResponse> cards = reviewService.getNewCards(userId, deckId, limit);
        return ResponseEntity.ok(ApiResponse.success(cards));
    }

    @GetMapping(value = "/new", produces = ProtobufHttpMessageConverter.APPLICATION_X_PROTOBUF_VALUE)
    public ResponseEntity<KarisReviewProto.ReviewCardListResponse> getNewCardsProto(
            @AuthenticationPrincipal UUID userId,
            @RequestParam(name = "deck_id", required = false) UUID deckId,
            @RequestParam(defaultValue = "10") int limit) {
        List<ReviewCardResponse> cards = reviewService.getNewCards(userId, deckId, limit);
        return ResponseEntity.ok(protoMapper.toCardList(cards));
    }

    @PostMapping(value = "/sessions",
            consumes = MediaType.APPLICATION_JSON_VALUE,
            produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<ReviewSessionPageResponse>> createSession(
            @AuthenticationPrincipal UUID userId,
            @Valid @RequestBody ReviewSessionCreateRequest request) {
        ReviewSessionPageResponse response = reviewService.createSession(userId, request);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @PostMapping(value = "/sessions",
            consumes = ProtobufHttpMessageConverter.APPLICATION_X_PROTOBUF_VALUE,
            produces = ProtobufHttpMessageConverter.APPLICATION_X_PROTOBUF_VALUE)
    public ResponseEntity<KarisReviewProto.ReviewSessionPageResponse> createSessionProto(
            @AuthenticationPrincipal UUID userId,
            @RequestBody KarisReviewProto.ReviewSessionCreateRequest request) {
        ReviewSessionPageResponse response = reviewService.createSession(
                userId, protoMapper.fromProto(request));
        return ResponseEntity.ok(protoMapper.toProto(response));
    }

    @GetMapping(value = "/sessions/{sessionId}", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<ReviewSessionPageResponse>> getSessionPage(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID sessionId,
            @RequestParam(defaultValue = "0") int cursor,
            @RequestParam(defaultValue = "10") int limit) {
        ReviewSessionPageResponse response = reviewService.getSessionPage(
                userId, sessionId, cursor, limit);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @GetMapping(value = "/sessions/{sessionId}",
            produces = ProtobufHttpMessageConverter.APPLICATION_X_PROTOBUF_VALUE)
    public ResponseEntity<KarisReviewProto.ReviewSessionPageResponse> getSessionPageProto(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID sessionId,
            @RequestParam(defaultValue = "0") int cursor,
            @RequestParam(defaultValue = "10") int limit) {
        ReviewSessionPageResponse response = reviewService.getSessionPage(
                userId, sessionId, cursor, limit);
        return ResponseEntity.ok(protoMapper.toProto(response));
    }

    @DeleteMapping("/sessions/{sessionId}")
    public ResponseEntity<ApiResponse<Void>> deleteSession(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID sessionId) {
        reviewService.deleteSession(userId, sessionId);
        return ResponseEntity.ok(ApiResponse.success("review.session.closed", null));
    }

    @PostMapping(value = "/sync",
            consumes = MediaType.APPLICATION_JSON_VALUE,
            produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<ReviewSyncResponse>> syncRatings(
            @AuthenticationPrincipal UUID userId,
            @Valid @RequestBody ReviewSyncRequest request) {
        ReviewSyncResponse response = reviewService.syncRatings(userId, request);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @PostMapping(value = "/sync",
            consumes = ProtobufHttpMessageConverter.APPLICATION_X_PROTOBUF_VALUE,
            produces = ProtobufHttpMessageConverter.APPLICATION_X_PROTOBUF_VALUE)
    public ResponseEntity<KarisReviewProto.ReviewSyncResponse> syncRatingsProto(
            @AuthenticationPrincipal UUID userId,
            @RequestBody KarisReviewProto.ReviewSyncRequest request) {
        ReviewSyncResponse response = reviewService.syncRatings(
                userId, protoMapper.fromProto(request));
        return ResponseEntity.ok(protoMapper.toProto(response));
    }

    @PostMapping(value = "/{cardId}/rate", consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<RateResponse>> rateCard(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID cardId,
            @Valid @RequestBody RateRequest request) {
        RateResponse response = reviewService.rateCard(userId, cardId, request);
        return ResponseEntity.ok(ApiResponse.success(response));
    }
}
