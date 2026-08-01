package top.kariscode.karisreview.card.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

public class CardResponse {

    private UUID id;
    private String front;
    private String back;
    private int stage;
    private LocalDate nextReviewDate;
    private boolean learningMode;
    private LocalDateTime createdAt;

    public CardResponse(UUID id, String front, String back, int stage,
                        LocalDate nextReviewDate, boolean learningMode,
                        LocalDateTime createdAt) {
        this.id = id;
        this.front = front;
        this.back = back;
        this.stage = stage;
        this.nextReviewDate = nextReviewDate;
        this.learningMode = learningMode;
        this.createdAt = createdAt;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
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
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}