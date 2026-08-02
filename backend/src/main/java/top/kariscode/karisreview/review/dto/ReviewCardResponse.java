package top.kariscode.karisreview.review.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.time.LocalDate;
import java.util.UUID;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class ReviewCardResponse {

    private UUID id;
    private UUID deckId;
    private String front;
    private String back;
    private int stage;
    private boolean learningMode;
    private int consecutiveFamiliar;
    private int learningStep;
    private int learningGoal;
    private Integer reentryStage;
    private LocalDate nextReviewDate;
    private int currentIntervalDays;
    private int familiarIntervalDays;
    private int vagueIntervalDays;
    private long reviewVersion;

    public ReviewCardResponse(UUID id, UUID deckId, String front, String back,
                              int stage, boolean learningMode, int consecutiveFamiliar,
                              int learningGoal, Integer reentryStage, LocalDate nextReviewDate,
                              int currentIntervalDays, int familiarIntervalDays,
                              int vagueIntervalDays) {
        this(id, deckId, front, back, stage, learningMode, consecutiveFamiliar,
                learningGoal, reentryStage, nextReviewDate, currentIntervalDays,
                familiarIntervalDays, vagueIntervalDays, 0, 0);
    }

    public ReviewCardResponse(UUID id, UUID deckId, String front, String back,
                              int stage, boolean learningMode, int consecutiveFamiliar,
                              int learningGoal, Integer reentryStage, LocalDate nextReviewDate,
                              int currentIntervalDays, int familiarIntervalDays,
                              int vagueIntervalDays, long reviewVersion) {
        this(id, deckId, front, back, stage, learningMode, consecutiveFamiliar,
                learningGoal, reentryStage, nextReviewDate, currentIntervalDays,
                familiarIntervalDays, vagueIntervalDays, 0, reviewVersion);
    }

    public ReviewCardResponse(UUID id, UUID deckId, String front, String back,
                              int stage, boolean learningMode, int consecutiveFamiliar,
                              int learningGoal, Integer reentryStage, LocalDate nextReviewDate,
                              int currentIntervalDays, int familiarIntervalDays,
                              int vagueIntervalDays, int learningStep, long reviewVersion) {
        this.id = id;
        this.deckId = deckId;
        this.front = front;
        this.back = back;
        this.stage = stage;
        this.learningMode = learningMode;
        this.consecutiveFamiliar = consecutiveFamiliar;
        this.learningStep = learningStep;
        this.learningGoal = learningGoal;
        this.reentryStage = reentryStage;
        this.nextReviewDate = nextReviewDate;
        this.currentIntervalDays = currentIntervalDays;
        this.familiarIntervalDays = familiarIntervalDays;
        this.vagueIntervalDays = vagueIntervalDays;
        this.reviewVersion = reviewVersion;
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
    public boolean isLearningMode() { return learningMode; }
    public void setLearningMode(boolean learningMode) { this.learningMode = learningMode; }
    public int getConsecutiveFamiliar() { return consecutiveFamiliar; }
    public void setConsecutiveFamiliar(int consecutiveFamiliar) { this.consecutiveFamiliar = consecutiveFamiliar; }
    public int getLearningStep() { return learningStep; }
    public void setLearningStep(int learningStep) { this.learningStep = learningStep; }
    public int getLearningGoal() { return learningGoal; }
    public void setLearningGoal(int learningGoal) { this.learningGoal = learningGoal; }
    public Integer getReentryStage() { return reentryStage; }
    public void setReentryStage(Integer reentryStage) { this.reentryStage = reentryStage; }
    public LocalDate getNextReviewDate() { return nextReviewDate; }
    public void setNextReviewDate(LocalDate nextReviewDate) { this.nextReviewDate = nextReviewDate; }
    public int getCurrentIntervalDays() { return currentIntervalDays; }
    public void setCurrentIntervalDays(int currentIntervalDays) { this.currentIntervalDays = currentIntervalDays; }
    public int getFamiliarIntervalDays() { return familiarIntervalDays; }
    public void setFamiliarIntervalDays(int familiarIntervalDays) { this.familiarIntervalDays = familiarIntervalDays; }
    public int getVagueIntervalDays() { return vagueIntervalDays; }
    public void setVagueIntervalDays(int vagueIntervalDays) { this.vagueIntervalDays = vagueIntervalDays; }
    public long getReviewVersion() { return reviewVersion; }
    public void setReviewVersion(long reviewVersion) { this.reviewVersion = reviewVersion; }
}