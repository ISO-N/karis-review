package top.kariscode.karisreview.card.dto;

public class CardImportResult {

    private int importedCards;

    public CardImportResult() {}

    public CardImportResult(int importedCards) {
        this.importedCards = importedCards;
    }

    public int getImportedCards() { return importedCards; }
    public void setImportedCards(int importedCards) { this.importedCards = importedCards; }
}
