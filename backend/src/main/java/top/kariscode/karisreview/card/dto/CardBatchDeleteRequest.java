package top.kariscode.karisreview.card.dto;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.UUID;

public class CardBatchDeleteRequest {

    @NotEmpty(message = "卡片 ID 列表不能为空")
    @Size(max = 1000, message = "单次最多删除 1000 张卡片")
    private List<UUID> cardIds;

    public List<UUID> getCardIds() { return cardIds; }
    public void setCardIds(List<UUID> cardIds) { this.cardIds = cardIds; }
}
