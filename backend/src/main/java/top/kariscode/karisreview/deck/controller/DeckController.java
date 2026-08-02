package top.kariscode.karisreview.deck.controller;

import jakarta.validation.Valid;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import top.kariscode.karisreview.common.dto.ApiResponse;
import top.kariscode.karisreview.common.etag.UserEtagService;
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
    private final UserEtagService etagService;

    public DeckController(DeckService deckService, UserEtagService etagService) {
        this.deckService = deckService;
        this.etagService = etagService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<DeckResponse>>> getDecks(
            @AuthenticationPrincipal UUID userId,
            @RequestHeader(name = "If-None-Match", required = false) String ifNoneMatch) {
        String etag = etagService.decksEtag(userId);
        if (matches(ifNoneMatch, etag)) {
            return ResponseEntity.status(HttpStatus.NOT_MODIFIED).eTag(etag).build();
        }
        List<DeckResponse> decks = deckService.getUserDecks(userId);
        return ResponseEntity.ok()
                .eTag(etag)
                .cacheControl(CacheControl.noCache().cachePrivate())
                .body(ApiResponse.success(decks));
    }

    private boolean matches(String ifNoneMatch, String etag) {
        return ifNoneMatch != null && ("*".equals(ifNoneMatch) || ifNoneMatch.equals(etag));
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