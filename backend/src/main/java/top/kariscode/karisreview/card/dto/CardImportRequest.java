package top.kariscode.karisreview.card.dto;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;

import java.util.List;

public class CardImportRequest {

    @NotEmpty(message = "{validation.card.import.list.notempty}")
    @Size(max = 1000, message = "{validation.card.import.list.too.many}")
    private List<CardImportItem> cards;

    public List<CardImportItem> getCards() { return cards; }
    public void setCards(List<CardImportItem> cards) { this.cards = cards; }
}
