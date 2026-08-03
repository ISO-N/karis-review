package top.kariscode.karisreview.card.dto;

public class CardBatchDeleteResult {

    private int deletedCards;

    public CardBatchDeleteResult() {}

    public CardBatchDeleteResult(int deletedCards) {
        this.deletedCards = deletedCards;
    }

    public int getDeletedCards() { return deletedCards; }
    public void setDeletedCards(int deletedCards) { this.deletedCards = deletedCards; }
}
