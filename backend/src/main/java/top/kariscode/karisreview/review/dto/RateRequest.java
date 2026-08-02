package top.kariscode.karisreview.review.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public class RateRequest {

    @NotBlank(message = "评分不能为空")
    @Pattern(regexp = "^(FORGET|VAGUE|FAMILIAR)$", message = "评分必须为 FORGET, VAGUE 或 FAMILIAR")
    private String rating;

    private String clientRequestId;

    @Min(value = 0, message = "review_version 不能小于 0")
    private Integer reviewVersion;

    public String getRating() { return rating; }
    public void setRating(String rating) { this.rating = rating; }
    public String getClientRequestId() { return clientRequestId; }
    public void setClientRequestId(String clientRequestId) { this.clientRequestId = clientRequestId; }
    public Integer getReviewVersion() { return reviewVersion; }
    public void setReviewVersion(Integer reviewVersion) { this.reviewVersion = reviewVersion; }
}