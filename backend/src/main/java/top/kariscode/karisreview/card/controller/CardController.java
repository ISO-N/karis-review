package top.kariscode.karisreview.card.controller;

import jakarta.validation.Valid;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import top.kariscode.karisreview.card.dto.CardBatchDeleteRequest;
import top.kariscode.karisreview.card.dto.CardBatchDeleteResult;
import top.kariscode.karisreview.card.dto.CardCreateRequest;
import top.kariscode.karisreview.card.dto.CardResponse;
import top.kariscode.karisreview.card.dto.CardUpdateRequest;
import top.kariscode.karisreview.card.service.CardService;
import top.kariscode.karisreview.common.dto.ApiResponse;

import java.util.Map;
import java.util.UUID;

@SecurityRequirement(name = "bearerAuth")
@RestController
@RequestMapping("/api")
public class CardController {

    private final CardService cardService;

    public CardController(CardService cardService) {
        this.cardService = cardService;
    }

    @GetMapping("/decks/{deckId}/cards")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getCards(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID deckId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "all") String filter,
            @RequestParam(defaultValue = "") String q) {
        Page<CardResponse> cardPage = cardService.getDeckCards(
                userId, deckId, page, size, filter, q);
        Map<String, Object> data = Map.of(
                "content", cardPage.getContent(),
                "page", cardPage.getNumber(),
                "size", cardPage.getSize(),
                "total_elements", cardPage.getTotalElements(),
                "total_pages", cardPage.getTotalPages()
        );
        return ResponseEntity.ok(ApiResponse.success(data));
    }

    @PostMapping("/decks/{deckId}/cards")
    public ResponseEntity<ApiResponse<CardResponse>> createCard(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID deckId,
            @Valid @RequestBody CardCreateRequest request) {
        CardResponse card = cardService.createCard(userId, deckId, request);
        return ResponseEntity.ok(ApiResponse.success("card.created", card));
    }

    @GetMapping("/cards/{cardId}")
    public ResponseEntity<ApiResponse<CardResponse>> getCard(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID cardId) {
        CardResponse card = cardService.getCard(userId, cardId);
        return ResponseEntity.ok(ApiResponse.success(card));
    }

    @PutMapping("/cards/{cardId}")
    public ResponseEntity<ApiResponse<CardResponse>> updateCard(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID cardId,
            @Valid @RequestBody CardUpdateRequest request) {
        CardResponse card = cardService.updateCard(userId, cardId, request);
        return ResponseEntity.ok(ApiResponse.success("card.updated", card));
    }

    @DeleteMapping("/cards/{cardId}")
    public ResponseEntity<ApiResponse<Void>> deleteCard(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID cardId) {
        cardService.deleteCard(userId, cardId);
        return ResponseEntity.ok(ApiResponse.success("card.deleted", null));
    }

    @PostMapping("/cards/batch-delete")
    public ResponseEntity<ApiResponse<CardBatchDeleteResult>> batchDeleteCards(
            @AuthenticationPrincipal UUID userId,
            @Valid @RequestBody CardBatchDeleteRequest request) {
        int deletedCards = cardService.deleteCards(userId, request.getCardIds());
        return ResponseEntity.ok(ApiResponse.success(
                "card.batch.deleted", new CardBatchDeleteResult(deletedCards)));
    }
}