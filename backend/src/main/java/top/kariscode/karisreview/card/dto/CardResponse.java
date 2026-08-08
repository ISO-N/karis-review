package top.kariscode.karisreview.card.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class CardResponse {

    private UUID id;
    private UUID deckId;
    private String front;
    private String back;
    private int stage;
    private LocalDate nextReviewDate;
    private boolean learningMode;
    private int consecutiveFamiliar;
    private int learningStep;
    private Integer reentryStage;
    private boolean due;
    private LocalDateTime createdAt;
    private long reviewVersion;
    private String learningOrigin;

    public CardResponse(UUID id, UUID deckId, String front, String back, int stage,
                        LocalDate nextReviewDate, boolean learningMode,
                        int consecutiveFamiliar, int learningStep, Integer reentryStage,
                        boolean due, LocalDateTime createdAt) {
        this(id, deckId, front, back, stage, nextReviewDate, learningMode,
                consecutiveFamiliar, learningStep, reentryStage, due, createdAt, 0, null);
    }

    public CardResponse(UUID id, UUID deckId, String front, String back, int stage,
                        LocalDate nextReviewDate, boolean learningMode,
                        int consecutiveFamiliar, int learningStep, Integer reentryStage,
                        boolean due, LocalDateTime createdAt,
                        long reviewVersion) {
        this(id, deckId, front, back, stage, nextReviewDate, learningMode,
                consecutiveFamiliar, learningStep, reentryStage, due, createdAt,
                reviewVersion, null);
    }

    public CardResponse(UUID id, UUID deckId, String front, String back, int stage,
                        LocalDate nextReviewDate, boolean learningMode,
                        int consecutiveFamiliar, int learningStep, Integer reentryStage,
                        boolean due, LocalDateTime createdAt,
                        long reviewVersion, String learningOrigin) {
        this.id = id;
        this.deckId = deckId;
        this.front = front;
        this.back = back;
        this.stage = stage;
        this.nextReviewDate = nextReviewDate;
        this.learningMode = learningMode;
        this.consecutiveFamiliar = consecutiveFamiliar;
        this.learningStep = learningStep;
        this.reentryStage = reentryStage;
        this.due = due;
        this.createdAt = createdAt;
        this.reviewVersion = reviewVersion;
        this.learningOrigin = learningOrigin;
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
    public LocalDate getNextReviewDate() { return nextReviewDate; }
    public void setNextReviewDate(LocalDate nextReviewDate) { this.nextReviewDate = nextReviewDate; }
    public boolean isLearningMode() { return learningMode; }
    public void setLearningMode(boolean learningMode) { this.learningMode = learningMode; }
    public int getConsecutiveFamiliar() { return consecutiveFamiliar; }
    public void setConsecutiveFamiliar(int consecutiveFamiliar) { this.consecutiveFamiliar = consecutiveFamiliar; }
    public int getLearningStep() { return learningStep; }
    public void setLearningStep(int learningStep) { this.learningStep = learningStep; }
    public Integer getReentryStage() { return reentryStage; }
    public void setReentryStage(Integer reentryStage) { this.reentryStage = reentryStage; }
    public boolean isDue() { return due; }
    public void setDue(boolean due) { this.due = due; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public long getReviewVersion() { return reviewVersion; }
    public void setReviewVersion(long reviewVersion) { this.reviewVersion = reviewVersion; }
    public String getLearningOrigin() { return learningOrigin; }
    public void setLearningOrigin(String learningOrigin) { this.learningOrigin = learningOrigin; }
}
