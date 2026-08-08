package top.kariscode.karisreview.stats.dto;

import java.util.List;

/**
 * 卡组计数（架构评审候选 4，2026-08）。
 *
 * StatsService 暴露的卡组统计唯一出口：DeckService.toDeckResponse 与
 * StatsService.getDeckStats 共用同一份计数实现（此前 DeckService 内
 * 重复实现 6 项计数与 distributionFromRows）。
 */
public class DeckCounters {

    private int cardCount;
    private int dueCount;
    private int newCount;
    private int masteredCount;
    private List<Long> stageDistribution;
    private List<Long> dueStageDistribution;

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
}
