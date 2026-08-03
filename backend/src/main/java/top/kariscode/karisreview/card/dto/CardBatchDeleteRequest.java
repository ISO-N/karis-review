package top.kariscode.karisreview.card.dto;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.UUID;

public class CardBatchDeleteRequest {

    @NotEmpty(message = "{validation.card.batch.id.notempty}")
    @Size(max = 1000, message = "{validation.card.batch.id.too.many}")
    private List<UUID> cardIds;

    public List<UUID> getCardIds() { return cardIds; }
    public void setCardIds(List<UUID> cardIds) { this.cardIds = cardIds; }
}
