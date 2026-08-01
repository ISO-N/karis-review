package top.kariscode.karisreview.review.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.time.LocalDate;
import java.util.UUID;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class RateResponse {

    private UUID cardId;
    private String rating;
    private int stageBefore;
    private int stageAfter;
    private LocalDate nextReviewDate;
    private boolean learningMode;
    private int consecutiveFamiliar;

    public RateResponse() {}

    public RateResponse(UUID cardId, String rating, int stageBefore, int stageAfter,
                        LocalDate nextReviewDate, boolean learningMode, int consecutiveFamiliar) {
        this.cardId = cardId;
        this.rating = rating;
        this.stageBefore = stageBefore;
        this.stageAfter = stageAfter;
        this.nextReviewDate = nextReviewDate;
        this.learningMode = learningMode;
        this.consecutiveFamiliar = consecutiveFamiliar;
    }

    public UUID getCardId() { return cardId; }
    public void setCardId(UUID cardId) { this.cardId = cardId; }
    public String getRating() { return rating; }
    public void setRating(String rating) { this.rating = rating; }
    public int getStageBefore() { return stageBefore; }
    public void setStageBefore(int stageBefore) { this.stageBefore = stageBefore; }
    public int getStageAfter() { return stageAfter; }
    public void setStageAfter(int stageAfter) { this.stageAfter = stageAfter; }
    public LocalDate getNextReviewDate() { return nextReviewDate; }
    public void setNextReviewDate(LocalDate nextReviewDate) { this.nextReviewDate = nextReviewDate; }
    public boolean isLearningMode() { return learningMode; }
    public void setLearningMode(boolean learningMode) { this.learningMode = learningMode; }
    public int getConsecutiveFamiliar() { return consecutiveFamiliar; }
    public void setConsecutiveFamiliar(int consecutiveFamiliar) { this.consecutiveFamiliar = consecutiveFamiliar; }
}