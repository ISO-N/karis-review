package top.kariscode.karisreview.card.dto;

import jakarta.validation.constraints.NotBlank;

public class CardCreateRequest {

    @NotBlank(message = "正面内容不能为空")
    private String front;

    @NotBlank(message = "反面内容不能为空")
    private String back;

    public String getFront() { return front; }
    public void setFront(String front) { this.front = front; }
    public String getBack() { return back; }
    public void setBack(String back) { this.back = back; }
}