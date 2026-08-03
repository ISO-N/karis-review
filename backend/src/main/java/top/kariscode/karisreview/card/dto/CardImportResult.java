package top.kariscode.karisreview.card.dto;

import java.util.List;
import java.util.UUID;

public class CardImportResult {

    private int importedCards;
    private List<UUID> importedCardIds;

    public CardImportResult() {}

    public CardImportResult(int importedCards) {
        this(importedCards, List.of());
    }

    public CardImportResult(int importedCards, List<UUID> importedCardIds) {
        this.importedCards = importedCards;
        this.importedCardIds = importedCardIds;
    }

    public int getImportedCards() { return importedCards; }
    public void setImportedCards(int importedCards) { this.importedCards = importedCards; }
    public List<UUID> getImportedCardIds() { return importedCardIds; }
    public void setImportedCardIds(List<UUID> importedCardIds) { this.importedCardIds = importedCardIds; }
}
