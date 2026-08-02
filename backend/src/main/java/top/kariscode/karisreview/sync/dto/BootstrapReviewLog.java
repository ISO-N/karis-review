package top.kariscode.karisreview.sync.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public class BootstrapReviewLog {

    private UUID id;
    private UUID cardId;
    private String rating;
    private int stageBefore;
    private int stageAfter;
    private LocalDateTime reviewedAt;

    public BootstrapReviewLog() {}

    public BootstrapReviewLog(UUID id, UUID cardId, String rating,
                              int stageBefore, int stageAfter, LocalDateTime reviewedAt) {
        this.id = id;
        this.cardId = cardId;
        this.rating = rating;
        this.stageBefore = stageBefore;
        this.stageAfter = stageAfter;
        this.reviewedAt = reviewedAt;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getCardId() { return cardId; }
    public void setCardId(UUID cardId) { this.cardId = cardId; }
    public String getRating() { return rating; }
    public void setRating(String rating) { this.rating = rating; }
    public int getStageBefore() { return stageBefore; }
    public void setStageBefore(int stageBefore) { this.stageBefore = stageBefore; }
    public int getStageAfter() { return stageAfter; }
    public void setStageAfter(int stageAfter) { this.stageAfter = stageAfter; }
    public LocalDateTime getReviewedAt() { return reviewedAt; }
    public void setReviewedAt(LocalDateTime reviewedAt) { this.reviewedAt = reviewedAt; }
}
