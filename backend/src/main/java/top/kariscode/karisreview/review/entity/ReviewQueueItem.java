package top.kariscode.karisreview.review.entity;

import jakarta.persistence.*;
import java.util.UUID;

@Entity
@Table(name = "review_queue_items")
public class ReviewQueueItem {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "session_id", nullable = false)
    private UUID sessionId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(nullable = false)
    private int position;

    @Column(name = "card_id", nullable = false)
    private UUID cardId;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getSessionId() { return sessionId; }
    public void setSessionId(UUID sessionId) { this.sessionId = sessionId; }
    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }
    public int getPosition() { return position; }
    public void setPosition(int position) { this.position = position; }
    public UUID getCardId() { return cardId; }
    public void setCardId(UUID cardId) { this.cardId = cardId; }
}
