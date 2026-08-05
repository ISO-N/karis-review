package top.kariscode.karisreview.stats.entity;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * 每日复习统计预聚合：按 (用户 × 业务日 × 卡组) 汇总复习/新学次数。
 * deckId 为 NULL 的行表示用户当日全量汇总。
 */
@Entity
@Table(name = "daily_review_stats", uniqueConstraints = {
        @UniqueConstraint(name = "uk_daily_stats_user_date_deck", columnNames = {"user_id", "stat_date", "deck_id"})
})
public class DailyReviewStats {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "stat_date", nullable = false)
    private LocalDate statDate;

    @Column(name = "deck_id")
    private UUID deckId;

    @Column(name = "reviewed_count", nullable = false)
    private int reviewedCount = 0;

    @Column(name = "learned_count", nullable = false)
    private int learnedCount = 0;

    @Column(name = "unique_cards", nullable = false)
    private int uniqueCards = 0;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    @PreUpdate
    protected void onWrite() {
        updatedAt = LocalDateTime.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }
    public LocalDate getStatDate() { return statDate; }
    public void setStatDate(LocalDate statDate) { this.statDate = statDate; }
    public UUID getDeckId() { return deckId; }
    public void setDeckId(UUID deckId) { this.deckId = deckId; }
    public int getReviewedCount() { return reviewedCount; }
    public void setReviewedCount(int reviewedCount) { this.reviewedCount = reviewedCount; }
    public int getLearnedCount() { return learnedCount; }
    public void setLearnedCount(int learnedCount) { this.learnedCount = learnedCount; }
    public int getUniqueCards() { return uniqueCards; }
    public void setUniqueCards(int uniqueCards) { this.uniqueCards = uniqueCards; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
