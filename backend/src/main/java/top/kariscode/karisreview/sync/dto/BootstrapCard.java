package top.kariscode.karisreview.sync.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class BootstrapCard {

    private UUID id;
    private UUID deckId;
    private String front;
    private String back;
    private int stage;
    private int consecutiveFamiliar;
    private LocalDate nextReviewDate;
    private boolean learningMode;
    private Integer reentryStage;
    private int learningStep;
    private long reviewVersion;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public BootstrapCard() {}

    public BootstrapCard(UUID id, UUID deckId, String front, String back,
                         int stage, int consecutiveFamiliar, LocalDate nextReviewDate,
                         boolean learningMode, Integer reentryStage, int learningStep,
                         long reviewVersion, LocalDateTime createdAt, LocalDateTime updatedAt) {
        this.id = id;
        this.deckId = deckId;
        this.front = front;
        this.back = back;
        this.stage = stage;
        this.consecutiveFamiliar = consecutiveFamiliar;
        this.nextReviewDate = nextReviewDate;
        this.learningMode = learningMode;
        this.reentryStage = reentryStage;
        this.learningStep = learningStep;
        this.reviewVersion = reviewVersion;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getDeckId() { return deckId; }
    public void setDeckId(UUID deckId) { this.deckId = deckId; }
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
    public long getReviewVersion() { return reviewVersion; }
    public void setReviewVersion(long reviewVersion) { this.reviewVersion = reviewVersion; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
