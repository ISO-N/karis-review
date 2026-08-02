package top.kariscode.karisreview.card.dto;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;

import java.util.List;

public class CardImportRequest {

    @NotEmpty(message = "卡片列表不能为空")
    @Size(max = 1000, message = "单次最多导入 1000 张卡片")
    private List<CardImportItem> cards;

    public List<CardImportItem> getCards() { return cards; }
    public void setCards(List<CardImportItem> cards) { this.cards = cards; }
}
