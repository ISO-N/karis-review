package top.kariscode.karisreview.card.dto;

import jakarta.validation.constraints.NotBlank;

public class CardUpdateRequest {

    @NotBlank(message = "{validation.card.front.notblank}")
    private String front;

    @NotBlank(message = "{validation.card.back.notblank}")
    private String back;

    public String getFront() { return front; }
    public void setFront(String front) { this.front = front; }
    public String getBack() { return back; }
    public void setBack(String back) { this.back = back; }
}