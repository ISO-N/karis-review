package top.kariscode.karisreview.review.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.List;
import java.util.UUID;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class ReviewSessionPageResponse {

    private UUID sessionId;
    private String mode;
    private UUID deckId;
    private int batchSize;
    private int total;
    private int cursor;
    private boolean hasMore;
    private List<ReviewCardResponse> cards;

    public ReviewSessionPageResponse() {}

    public ReviewSessionPageResponse(UUID sessionId, String mode, UUID deckId,
                                     int batchSize, int total, int cursor,
                                     boolean hasMore, List<ReviewCardResponse> cards) {
        this.sessionId = sessionId;
        this.mode = mode;
        this.deckId = deckId;
        this.batchSize = batchSize;
        this.total = total;
        this.cursor = cursor;
        this.hasMore = hasMore;
        this.cards = cards;
    }

    public UUID getSessionId() { return sessionId; }
    public void setSessionId(UUID sessionId) { this.sessionId = sessionId; }
    public String getMode() { return mode; }
    public void setMode(String mode) { this.mode = mode; }
    public UUID getDeckId() { return deckId; }
    public void setDeckId(UUID deckId) { this.deckId = deckId; }
    public int getBatchSize() { return batchSize; }
    public void setBatchSize(int batchSize) { this.batchSize = batchSize; }
    public int getTotal() { return total; }
    public void setTotal(int total) { this.total = total; }
    public int getCursor() { return cursor; }
    public void setCursor(int cursor) { this.cursor = cursor; }
    public boolean isHasMore() { return hasMore; }
    public void setHasMore(boolean hasMore) { this.hasMore = hasMore; }
    public List<ReviewCardResponse> getCards() { return cards; }
    public void setCards(List<ReviewCardResponse> cards) { this.cards = cards; }
}
