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
    private List<BootstrapCard> changedCards;
    private List<String> deletedDeckIds;
    private List<String> deletedCardIds;
    private List<String> deletedReviewLogIds;
    private long eventCursor;
    private boolean hasMore;
    private boolean resetRequired;

    public BootstrapResponse() {}

    public BootstrapResponse(OffsetDateTime serverTime, BootstrapUser user,
                             List<BootstrapDeck> decks, List<BootstrapReviewLog> reviewLogs) {
        this(serverTime, user, decks, reviewLogs, List.of(),
                List.of(), List.of(), List.of(), 0, false, false);
    }

    public BootstrapResponse(OffsetDateTime serverTime, BootstrapUser user,
                             List<BootstrapDeck> decks, List<BootstrapReviewLog> reviewLogs,
                             List<BootstrapCard> changedCards,
                             List<String> deletedDeckIds, List<String> deletedCardIds,
                             List<String> deletedReviewLogIds,
                             long eventCursor, boolean hasMore, boolean resetRequired) {
        this.serverTime = serverTime;
        this.user = user;
        this.decks = decks;
        this.reviewLogs = reviewLogs;
        this.changedCards = changedCards;
        this.deletedDeckIds = deletedDeckIds;
        this.deletedCardIds = deletedCardIds;
        this.deletedReviewLogIds = deletedReviewLogIds;
        this.eventCursor = eventCursor;
        this.hasMore = hasMore;
        this.resetRequired = resetRequired;
    }

    public OffsetDateTime getServerTime() { return serverTime; }
    public void setServerTime(OffsetDateTime serverTime) { this.serverTime = serverTime; }
    public BootstrapUser getUser() { return user; }
    public void setUser(BootstrapUser user) { this.user = user; }
    public List<BootstrapDeck> getDecks() { return decks; }
    public void setDecks(List<BootstrapDeck> decks) { this.decks = decks; }
    public List<BootstrapReviewLog> getReviewLogs() { return reviewLogs; }
    public void setReviewLogs(List<BootstrapReviewLog> reviewLogs) { this.reviewLogs = reviewLogs; }
    public List<BootstrapCard> getChangedCards() { return changedCards; }
    public void setChangedCards(List<BootstrapCard> changedCards) { this.changedCards = changedCards; }
    public List<String> getDeletedDeckIds() { return deletedDeckIds; }
    public void setDeletedDeckIds(List<String> deletedDeckIds) { this.deletedDeckIds = deletedDeckIds; }
    public List<String> getDeletedCardIds() { return deletedCardIds; }
    public void setDeletedCardIds(List<String> deletedCardIds) { this.deletedCardIds = deletedCardIds; }
    public List<String> getDeletedReviewLogIds() { return deletedReviewLogIds; }
    public void setDeletedReviewLogIds(List<String> deletedReviewLogIds) { this.deletedReviewLogIds = deletedReviewLogIds; }
    public long getEventCursor() { return eventCursor; }
    public void setEventCursor(long eventCursor) { this.eventCursor = eventCursor; }
    public boolean isHasMore() { return hasMore; }
    public void setHasMore(boolean hasMore) { this.hasMore = hasMore; }
    public boolean isResetRequired() { return resetRequired; }
    public void setResetRequired(boolean resetRequired) { this.resetRequired = resetRequired; }
}
