package top.kariscode.karisreview.deck.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public class DeckResponse {

    private UUID id;
    private String name;
    private int cardCount;
    private int dueCount;
    private LocalDateTime createdAt;

    public DeckResponse(UUID id, String name, int cardCount, int dueCount, LocalDateTime createdAt) {
        this.id = id;
        this.name = name;
        this.cardCount = cardCount;
        this.dueCount = dueCount;
        this.createdAt = createdAt;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public int getCardCount() { return cardCount; }
    public void setCardCount(int cardCount) { this.cardCount = cardCount; }
    public int getDueCount() { return dueCount; }
    public void setDueCount(int dueCount) { this.dueCount = dueCount; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}