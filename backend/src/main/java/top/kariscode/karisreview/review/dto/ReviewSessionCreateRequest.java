package top.kariscode.karisreview.review.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

import java.util.UUID;

public class ReviewSessionCreateRequest {

    @NotBlank(message = "模式不能为空")
    @Pattern(regexp = "^(due|new)$", message = "模式必须为 due 或 new")
    private String mode;

    private UUID deckId;

    @Min(value = 1, message = "每页数量至少为 1")
    @Max(value = 50, message = "每页数量最多为 50")
    private Integer batchSize = 10;

    public String getMode() { return mode; }
    public void setMode(String mode) { this.mode = mode; }
    public UUID getDeckId() { return deckId; }
    public void setDeckId(UUID deckId) { this.deckId = deckId; }
    public Integer getBatchSize() { return batchSize; }
    public void setBatchSize(Integer batchSize) { this.batchSize = batchSize; }
}
