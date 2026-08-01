package top.kariscode.karisreview.review.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public class RateRequest {

    @NotBlank(message = "评分不能为空")
    @Pattern(regexp = "^(FORGET|VAGUE|FAMILIAR)$", message = "评分必须为 FORGET, VAGUE 或 FAMILIAR")
    private String rating;

    public String getRating() { return rating; }
    public void setRating(String rating) { this.rating = rating; }
}