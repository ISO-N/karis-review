package top.kariscode.karisreview.card.entity;

import jakarta.persistence.*;
import java.time.LocalDate;
import top.kariscode.karisreview.common.util.DateUtils;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "cards")
public class Card {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "deck_id", nullable = false)
    private UUID deckId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String front;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String back;

    @Column(nullable = false)
    private int stage = 0;

    @Column(name = "consecutive_familiar", nullable = false)
    private int consecutiveFamiliar = 0;

    @Column(name = "next_review_date")
    private LocalDate nextReviewDate;

    @Column(name = "learning_mode", nullable = false)
    private boolean learningMode = false;

    @Column(name = "reentry_stage")
    private Integer reentryStage;

    @Column(name = "learning_step", nullable = false)
    private int learningStep = 0;

    /**
     * 学习来源：进入重学模式时所属的阶段。
     * "NEW"（学新阶段忘记）/ "REVIEW"（复习阶段忘记/模糊）/ null（非重学或旧数据）。
     * 决定重学卡归学新队列还是复习队列。
     */
    @Column(name = "learning_origin")
    private String learningOrigin;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @Version
    @Column(name = "review_version", nullable = false)
    private long reviewVersion = 0;

    @PrePersist
    protected void onCreate() {
        createdAt = DateUtils.now();
        updatedAt = DateUtils.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = DateUtils.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getDeckId() { return deckId; }
    public void setDeckId(UUID deckId) { this.deckId = deckId; }
    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }
    public String getFront() { return front; }
    public void setFront(String front) { this.front = front; }
    public String getBack() { return back; }
    public void setBack(String back) { this.back = back; }
    public int getStage() { return stage; }
    public void setStage(int stage) { this.stage = stage; }
    public int getConsecutiveFamiliar() { return consecutiveFamiliar; }
    public void setConsecutiveFamiliar(int consecutiveFamiliar) { this.consecutiveFamiliar = consecutiveFamiliar; }
    public LocalDate getNextReviewDate() { return nextReviewDate; }
    public void setNextReviewDate(LocalDate nextReviewDate) { this.nextReviewDate = nextReviewDate; }
    public boolean isLearningMode() { return learningMode; }
    public void setLearningMode(boolean learningMode) { this.learningMode = learningMode; }
    public Integer getReentryStage() { return reentryStage; }
    public void setReentryStage(Integer reentryStage) { this.reentryStage = reentryStage; }
    public int getLearningStep() { return learningStep; }
    public void setLearningStep(int learningStep) { this.learningStep = learningStep; }
    public String getLearningOrigin() { return learningOrigin; }
    public void setLearningOrigin(String learningOrigin) { this.learningOrigin = learningOrigin; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public long getReviewVersion() { return reviewVersion; }
    public void setReviewVersion(long reviewVersion) { this.reviewVersion = reviewVersion; }

    /**
     * 排期状态（架构评审候选 2）：stage/consecutiveFamiliar/nextReviewDate/
     * learningMode/reentryStage/learningStep/learningOrigin 的唯一出口。
     * DTO 与备份投影必须经由此对象，禁止逐字段散落读取。
     */
    public SchedulingState getSchedulingState() {
        return SchedulingState.from(this);
    }

    /** 应用排期状态（备份导入 / 恢复用）。 */
    public void applySchedulingState(SchedulingState s) {
        this.stage = s.getStage();
        this.consecutiveFamiliar = s.getConsecutiveFamiliar();
        this.nextReviewDate = s.getNextReviewDate();
        this.learningMode = s.isLearningMode();
        this.reentryStage = s.getReentryStage();
        this.learningStep = s.getLearningStep();
        this.learningOrigin = s.getLearningOrigin();
    }
}