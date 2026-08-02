package top.kariscode.karisreview.sync.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.time.OffsetDateTime;
import java.util.List;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class BootstrapResponse {

    private OffsetDateTime serverTime;
    private BootstrapUser user;
    private List<BootstrapDeck> decks;
    private List<BootstrapReviewLog> reviewLogs;

    public BootstrapResponse() {}

    public BootstrapResponse(OffsetDateTime serverTime, BootstrapUser user,
                             List<BootstrapDeck> decks, List<BootstrapReviewLog> reviewLogs) {
        this.serverTime = serverTime;
        this.user = user;
        this.decks = decks;
        this.reviewLogs = reviewLogs;
    }

    public OffsetDateTime getServerTime() { return serverTime; }
    public void setServerTime(OffsetDateTime serverTime) { this.serverTime = serverTime; }
    public BootstrapUser getUser() { return user; }
    public void setUser(BootstrapUser user) { this.user = user; }
    public List<BootstrapDeck> getDecks() { return decks; }
    public void setDecks(List<BootstrapDeck> decks) { this.decks = decks; }
    public List<BootstrapReviewLog> getReviewLogs() { return reviewLogs; }
    public void setReviewLogs(List<BootstrapReviewLog> reviewLogs) { this.reviewLogs = reviewLogs; }
}
