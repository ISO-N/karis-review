package top.kariscode.karisreview.review.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public class RateRequest {

    @NotBlank(message = "{validation.rating.notblank}")
    @Pattern(regexp = "^(FORGET|VAGUE|FAMILIAR)$", message = "{validation.rating.pattern}")
    private String rating;

    private String clientRequestId;

    @Min(value = 0, message = "{validation.review.version.min}")
    private Integer reviewVersion;

    public String getRating() { return rating; }
    public void setRating(String rating) { this.rating = rating; }
    public String getClientRequestId() { return clientRequestId; }
    public void setClientRequestId(String clientRequestId) { this.clientRequestId = clientRequestId; }
    public Integer getReviewVersion() { return reviewVersion; }
    public void setReviewVersion(Integer reviewVersion) { this.reviewVersion = reviewVersion; }
}