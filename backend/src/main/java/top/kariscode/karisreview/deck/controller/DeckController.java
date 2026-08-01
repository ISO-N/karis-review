package top.kariscode.karisreview.deck.controller;

import jakarta.validation.Valid;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import top.kariscode.karisreview.common.dto.ApiResponse;
import top.kariscode.karisreview.deck.dto.DeckCreateRequest;
import top.kariscode.karisreview.deck.dto.DeckResponse;
import top.kariscode.karisreview.deck.dto.DeckUpdateRequest;
import top.kariscode.karisreview.deck.service.DeckService;

import java.util.List;
import java.util.UUID;

@SecurityRequirement(name = "bearerAuth")
@RestController
@RequestMapping("/api/decks")
public class DeckController {

    private final DeckService deckService;

    public DeckController(DeckService deckService) {
        this.deckService = deckService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<DeckResponse>>> getDecks(@AuthenticationPrincipal UUID userId) {
        List<DeckResponse> decks = deckService.getUserDecks(userId);
        return ResponseEntity.ok(ApiResponse.success(decks));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<DeckResponse>> createDeck(
            @AuthenticationPrincipal UUID userId,
            @Valid @RequestBody DeckCreateRequest request) {
        DeckResponse deck = deckService.createDeck(userId, request);
        return ResponseEntity.ok(ApiResponse.success("牌组已创建", deck));
    }

    @PutMapping("/{deckId}")
    public ResponseEntity<ApiResponse<DeckResponse>> updateDeck(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID deckId,
            @Valid @RequestBody DeckUpdateRequest request) {
        DeckResponse deck = deckService.updateDeck(userId, deckId, request);
        return ResponseEntity.ok(ApiResponse.success("牌组已更新", deck));
    }

    @DeleteMapping("/{deckId}")
    public ResponseEntity<ApiResponse<Void>> deleteDeck(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID deckId) {
        deckService.deleteDeck(userId, deckId);
        return ResponseEntity.ok(ApiResponse.success("牌组已删除", null));
    }
}