package top.kariscode.karisreview.stats.dto;

import java.util.Map;

public class DeckStatsResponse {

    private String deckId;
    private String deckName;
    private long totalCards;
    private long dueToday;
    private long reviewedToday;
    private Map<String, Long> stageDistribution;

    public String getDeckId() { return deckId; }
    public void setDeckId(String deckId) { this.deckId = deckId; }
    public String getDeckName() { return deckName; }
    public void setDeckName(String deckName) { this.deckName = deckName; }
    public long getTotalCards() { return totalCards; }
    public void setTotalCards(long totalCards) { this.totalCards = totalCards; }
    public long getDueToday() { return dueToday; }
    public void setDueToday(long dueToday) { this.dueToday = dueToday; }
    public long getReviewedToday() { return reviewedToday; }
    public void setReviewedToday(long reviewedToday) { this.reviewedToday = reviewedToday; }
    public Map<String, Long> getStageDistribution() { return stageDistribution; }
    public void setStageDistribution(Map<String, Long> stageDistribution) { this.stageDistribution = stageDistribution; }
}