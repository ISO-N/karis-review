package top.kariscode.karisreview.review.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;

import java.util.List;

public class ReviewSyncRequest {

    @Valid
    @NotEmpty(message = "同步条目不能为空")
    @Size(max = 500, message = "单次同步最多 500 条")
    private List<ReviewSyncItem> items;

    public List<ReviewSyncItem> getItems() { return items; }
    public void setItems(List<ReviewSyncItem> items) { this.items = items; }
}
