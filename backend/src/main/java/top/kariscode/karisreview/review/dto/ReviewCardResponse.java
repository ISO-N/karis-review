package top.kariscode.karisreview.review.dto;

import java.util.UUID;

public class ReviewCardResponse {

    private UUID id;
    private UUID deckId;
    private String front;
    private String back;
    private int stage;
    private boolean learningMode;
    private int consecutiveFamiliar;

    public ReviewCardResponse(UUID id, UUID deckId, String front, String back,
                              int stage, boolean learningMode, int consecutiveFamiliar) {
        this.id = id;
        this.deckId = deckId;
        this.front = front;
        this.back = back;
        this.stage = stage;
        this.learningMode = learningMode;
        this.consecutiveFamiliar = consecutiveFamiliar;
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
}