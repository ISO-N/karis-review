package top.kariscode.karisreview.stats.dto;

import java.time.LocalDate;

public class TrendStatsResponse {

    private LocalDate date;
    private long reviewed;
    private long learned;

    public TrendStatsResponse(LocalDate date, long reviewed, long learned) {
        this.date = date;
        this.reviewed = reviewed;
        this.learned = learned;
    }

    public LocalDate getDate() { return date; }
    public void setDate(LocalDate date) { this.date = date; }
    public long getReviewed() { return reviewed; }
    public void setReviewed(long reviewed) { this.reviewed = reviewed; }
    public long getLearned() { return learned; }
    public void setLearned(long learned) { this.learned = learned; }
}