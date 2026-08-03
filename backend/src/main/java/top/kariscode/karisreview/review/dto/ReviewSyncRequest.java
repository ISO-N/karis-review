package top.kariscode.karisreview.review.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;

import java.util.List;

public class ReviewSyncRequest {

    @Valid
    @NotEmpty(message = "{validation.sync.list.notempty}")
    @Size(max = 500, message = "{validation.sync.list.too.many}")
    private List<ReviewSyncItem> items;

    public List<ReviewSyncItem> getItems() { return items; }
    public void setItems(List<ReviewSyncItem> items) { this.items = items; }
}
