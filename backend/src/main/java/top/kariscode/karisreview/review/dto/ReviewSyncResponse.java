package top.kariscode.karisreview.review.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.List;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class ReviewSyncResponse {

    private int synced;
    private int conflicts;
    private int missing;
    private List<ReviewSyncItemResult> items;

    public ReviewSyncResponse() {}

    public ReviewSyncResponse(int synced, int conflicts, int missing,
                              List<ReviewSyncItemResult> items) {
        this.synced = synced;
        this.conflicts = conflicts;
        this.missing = missing;
        this.items = items;
    }

    public int getSynced() { return synced; }
    public void setSynced(int synced) { this.synced = synced; }
    public int getConflicts() { return conflicts; }
    public void setConflicts(int conflicts) { this.conflicts = conflicts; }
    public int getMissing() { return missing; }
    public void setMissing(int missing) { this.missing = missing; }
    public List<ReviewSyncItemResult> getItems() { return items; }
    public void setItems(List<ReviewSyncItemResult> items) { this.items = items; }
}
