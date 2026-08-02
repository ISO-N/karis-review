package top.kariscode.karisreview.deck.dto;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public class DeckResponse {

    private UUID id;
    private String name;
    private int cardCount;
    private int dueCount;
    private int newCount;
    private int masteredCount;
    private List<Long> stageDistribution;
    private List<Long> dueStageDistribution;
    private LocalDateTime createdAt;

    public DeckResponse(UUID id, String name, int cardCount, int dueCount,
                        int newCount, int masteredCount,
                        List<Long> stageDistribution,
                        List<Long> dueStageDistribution,
                        LocalDateTime createdAt) {
        this.id = id;
        this.name = name;
        this.cardCount = cardCount;
        this.dueCount = dueCount;
        this.newCount = newCount;
        this.masteredCount = masteredCount;
        this.stageDistribution = stageDistribution;
        this.dueStageDistribution = dueStageDistribution;
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
    public int getNewCount() { return newCount; }
    public void setNewCount(int newCount) { this.newCount = newCount; }
    public int getMasteredCount() { return masteredCount; }
    public void setMasteredCount(int masteredCount) { this.masteredCount = masteredCount; }
    public List<Long> getStageDistribution() { return stageDistribution; }
    public void setStageDistribution(List<Long> stageDistribution) { this.stageDistribution = stageDistribution; }
    public List<Long> getDueStageDistribution() { return dueStageDistribution; }
    public void setDueStageDistribution(List<Long> dueStageDistribution) { this.dueStageDistribution = dueStageDistribution; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
