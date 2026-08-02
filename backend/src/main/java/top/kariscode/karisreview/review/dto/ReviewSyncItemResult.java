package top.kariscode.karisreview.review.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class ReviewSyncItemResult {

    private String clientRequestId;
    private String status;
    private RateResponse result;
    private ReviewCardResponse currentCard;

    public ReviewSyncItemResult() {}

    public ReviewSyncItemResult(String clientRequestId, String status,
                                RateResponse result, ReviewCardResponse currentCard) {
        this.clientRequestId = clientRequestId;
        this.status = status;
        this.result = result;
        this.currentCard = currentCard;
    }

    public String getClientRequestId() { return clientRequestId; }
    public void setClientRequestId(String clientRequestId) { this.clientRequestId = clientRequestId; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public RateResponse getResult() { return result; }
    public void setResult(RateResponse result) { this.result = result; }
    public ReviewCardResponse getCurrentCard() { return currentCard; }
    public void setCurrentCard(ReviewCardResponse currentCard) { this.currentCard = currentCard; }
}
