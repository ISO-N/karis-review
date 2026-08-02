package top.kariscode.karisreview.card.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class CardImportPreviewItem {

    private int index;
    private String front;
    private String back;
    private boolean valid;
    private String message;

    public CardImportPreviewItem() {}

    public CardImportPreviewItem(int index, String front, String back,
                                 boolean valid, String message) {
        this.index = index;
        this.front = front;
        this.back = back;
        this.valid = valid;
        this.message = message;
    }

    public int getIndex() { return index; }
    public void setIndex(int index) { this.index = index; }
    public String getFront() { return front; }
    public void setFront(String front) { this.front = front; }
    public String getBack() { return back; }
    public void setBack(String back) { this.back = back; }
    public boolean isValid() { return valid; }
    public void setValid(boolean valid) { this.valid = valid; }
    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }
}
