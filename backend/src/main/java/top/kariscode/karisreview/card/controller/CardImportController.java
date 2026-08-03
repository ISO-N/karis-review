package top.kariscode.karisreview.card.controller;

import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import top.kariscode.karisreview.card.dto.CardImportPreviewRequest;
import top.kariscode.karisreview.card.dto.CardImportPreviewResponse;
import top.kariscode.karisreview.card.dto.CardImportRequest;
import top.kariscode.karisreview.card.dto.CardImportResult;
import top.kariscode.karisreview.card.service.CardImportService;
import top.kariscode.karisreview.common.dto.ApiResponse;

import java.util.UUID;

@SecurityRequirement(name = "bearerAuth")
@RestController
@RequestMapping("/api/decks/{deckId}/cards/import")
public class CardImportController {

    private final CardImportService cardImportService;

    public CardImportController(CardImportService cardImportService) {
        this.cardImportService = cardImportService;
    }

    @PostMapping("/preview")
    public ResponseEntity<ApiResponse<CardImportPreviewResponse>> preview(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID deckId,
            @Valid @RequestBody CardImportPreviewRequest request) {
        CardImportPreviewResponse preview =
                cardImportService.preview(userId, deckId, request.getContent());
        return ResponseEntity.ok(ApiResponse.success("card.import.parsed", preview));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<CardImportResult>> importCards(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID deckId,
            @Valid @RequestBody CardImportRequest request) {
        CardImportResult result = cardImportService.importCards(userId, deckId, request);
        return ResponseEntity.ok(ApiResponse.success("card.import.success", result));
    }
}
