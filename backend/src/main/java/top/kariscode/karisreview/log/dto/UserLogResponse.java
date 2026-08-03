package top.kariscode.karisreview.log.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.time.LocalDateTime;
import java.util.UUID;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class UserLogResponse {

    private UUID id;
    private String level;
    private String category;
    private String message;
    private Object details;
    private LocalDateTime createdAt;

    public UserLogResponse() {}

    public UserLogResponse(UUID id, String level, String category, String message,
                           Object details, LocalDateTime createdAt) {
        this.id = id;
        this.level = level;
        this.category = category;
        this.message = message;
        this.details = details;
        this.createdAt = createdAt;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public String getLevel() { return level; }
    public void setLevel(String level) { this.level = level; }
    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }
    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }
    public Object getDetails() { return details; }
    public void setDetails(Object details) { this.details = details; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}