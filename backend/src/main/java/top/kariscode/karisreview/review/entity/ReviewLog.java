package top.kariscode.karisreview.review.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "review_logs")
public class ReviewLog {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "card_id", nullable = false)
    private UUID cardId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(nullable = false, length = 10)
    private String rating;

    @Column(name = "stage_before", nullable = false)
    private int stageBefore;

    @Column(name = "stage_after", nullable = false)
    private int stageAfter;

    @Column(name = "is_new_card", nullable = false)
    private boolean newCard;

    @Column(name = "client_request_id")
    private String clientRequestId;

    @Column(name = "reviewed_at", nullable = false, updatable = false)
    private LocalDateTime reviewedAt;

    @PrePersist
    protected void onCreate() {
        if (reviewedAt == null) {
            reviewedAt = LocalDateTime.now();
        }
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getCardId() { return cardId; }
    public void setCardId(UUID cardId) { this.cardId = cardId; }
    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }
    public String getRating() { return rating; }
    public void setRating(String rating) { this.rating = rating; }
    public int getStageBefore() { return stageBefore; }
    public void setStageBefore(int stageBefore) { this.stageBefore = stageBefore; }
    public int getStageAfter() { return stageAfter; }
    public void setStageAfter(int stageAfter) { this.stageAfter = stageAfter; }
    public boolean isNewCard() { return newCard; }
    public void setNewCard(boolean newCard) { this.newCard = newCard; }
    public String getClientRequestId() { return clientRequestId; }
    public void setClientRequestId(String clientRequestId) { this.clientRequestId = clientRequestId; }
    public LocalDateTime getReviewedAt() { return reviewedAt; }
    public void setReviewedAt(LocalDateTime reviewedAt) { this.reviewedAt = reviewedAt; }
}