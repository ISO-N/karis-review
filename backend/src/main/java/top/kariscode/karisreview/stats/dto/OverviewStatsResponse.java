package top.kariscode.karisreview.stats.dto;

import java.util.Map;

public class OverviewStatsResponse {

    private long totalCards;
    private long totalDecks;
    private long dueToday;
    private long reviewedToday;
    private long learnedToday;
    private long masteredCards;
    private long learningCards;
    private Map<String, Long> stageDistribution;
    private Map<String, Long> dueStageDistribution;

    public long getTotalCards() { return totalCards; }
    public void setTotalCards(long totalCards) { this.totalCards = totalCards; }
    public long getTotalDecks() { return totalDecks; }
    public void setTotalDecks(long totalDecks) { this.totalDecks = totalDecks; }
    public long getDueToday() { return dueToday; }
    public void setDueToday(long dueToday) { this.dueToday = dueToday; }
    public long getReviewedToday() { return reviewedToday; }
    public void setReviewedToday(long reviewedToday) { this.reviewedToday = reviewedToday; }
    public long getLearnedToday() { return learnedToday; }
    public void setLearnedToday(long learnedToday) { this.learnedToday = learnedToday; }
    public long getMasteredCards() { return masteredCards; }
    public void setMasteredCards(long masteredCards) { this.masteredCards = masteredCards; }
    public long getLearningCards() { return learningCards; }
    public void setLearningCards(long learningCards) { this.learningCards = learningCards; }
    public Map<String, Long> getStageDistribution() { return stageDistribution; }
    public void setStageDistribution(Map<String, Long> stageDistribution) { this.stageDistribution = stageDistribution; }
    public Map<String, Long> getDueStageDistribution() { return dueStageDistribution; }
    public void setDueStageDistribution(Map<String, Long> dueStageDistribution) { this.dueStageDistribution = dueStageDistribution; }
}
