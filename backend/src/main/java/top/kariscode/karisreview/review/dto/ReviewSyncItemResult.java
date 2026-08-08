package top.kariscode.karisreview.review.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.UUID;

/**
 * 单条评分同步结果。
 *
 * <p>cardId：评分卡片的 ID（2026-08-08 架构评审 A4 补齐——proto 早已声明
 * optional card_id 但后端从未填充；现 JSON/protobuf 双通道都输出，前端
 * CARD_NOT_FOUND 时可省掉本地反查）。</p>
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ReviewSyncItemResult {

    private String clientRequestId;
    private String status;
    private ReviewCardResponse currentCard;
    private UUID cardId;

    public ReviewSyncItemResult() {}

    public ReviewSyncItemResult(String clientRequestId, String status,
                                ReviewCardResponse currentCard) {
        this.clientRequestId = clientRequestId;
        this.status = status;
        this.currentCard = currentCard;
    }

    public ReviewSyncItemResult(String clientRequestId, String status,
                                ReviewCardResponse currentCard, UUID cardId) {
        this.clientRequestId = clientRequestId;
        this.status = status;
        this.currentCard = currentCard;
        this.cardId = cardId;
    }

    public String getClientRequestId() { return clientRequestId; }
    public void setClientRequestId(String clientRequestId) { this.clientRequestId = clientRequestId; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public ReviewCardResponse getCurrentCard() { return currentCard; }
    public void setCurrentCard(ReviewCardResponse currentCard) { this.currentCard = currentCard; }
    public UUID getCardId() { return cardId; }
    public void setCardId(UUID cardId) { this.cardId = cardId; }
}
