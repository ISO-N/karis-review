package top.kariscode.karisreview.card.dto;

import java.util.List;

public class CardImportPreviewResponse {

    private int total;
    private int validCount;
    private int invalidCount;
    private List<CardImportPreviewItem> cards;

    public CardImportPreviewResponse() {}

    public CardImportPreviewResponse(int total, int validCount, int invalidCount,
                                     List<CardImportPreviewItem> cards) {
        this.total = total;
        this.validCount = validCount;
        this.invalidCount = invalidCount;
        this.cards = cards;
    }

    public int getTotal() { return total; }
    public void setTotal(int total) { this.total = total; }
    public int getValidCount() { return validCount; }
    public void setValidCount(int validCount) { this.validCount = validCount; }
    public int getInvalidCount() { return invalidCount; }
    public void setInvalidCount(int invalidCount) { this.invalidCount = invalidCount; }
    public List<CardImportPreviewItem> getCards() { return cards; }
    public void setCards(List<CardImportPreviewItem> cards) { this.cards = cards; }
}
