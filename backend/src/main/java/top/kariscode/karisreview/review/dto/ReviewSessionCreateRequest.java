package top.kariscode.karisreview.review.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

import java.util.UUID;

public class ReviewSessionCreateRequest {

    @NotBlank(message = "{validation.session.mode.notblank}")
    @Pattern(regexp = "^(due|new)$", message = "{validation.session.mode.pattern}")
    private String mode;

    private UUID deckId;

    @Min(value = 1, message = "{validation.session.size.min}")
    @Max(value = 50, message = "{validation.session.size.max}")
    private Integer batchSize = 10;

    public String getMode() { return mode; }
    public void setMode(String mode) { this.mode = mode; }
    public UUID getDeckId() { return deckId; }
    public void setDeckId(UUID deckId) { this.deckId = deckId; }
    public Integer getBatchSize() { return batchSize; }
    public void setBatchSize(Integer batchSize) { this.batchSize = batchSize; }
}
