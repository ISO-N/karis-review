package top.kariscode.karisreview.review.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

import java.time.OffsetDateTime;
import java.util.UUID;

public class ReviewSyncItem {

    @NotBlank(message = "{validation.sync.item.client.id.notblank}")
    private String clientRequestId;

    @NotNull(message = "{validation.sync.item.card.id.notnull}")
    private UUID cardId;

    @NotBlank(message = "{validation.sync.item.rating.notblank}")
    @Pattern(regexp = "^(FORGET|VAGUE|FAMILIAR)$", message = "{validation.sync.item.rating.pattern}")
    private String rating;

    @NotNull(message = "{validation.sync.item.rated.at.notnull}")
    private OffsetDateTime ratedAt;

    @Min(value = 0, message = "review_version 不能小于 0")
    private long reviewVersion;

    public String getClientRequestId() { return clientRequestId; }
    public void setClientRequestId(String clientRequestId) { this.clientRequestId = clientRequestId; }
    public UUID getCardId() { return cardId; }
    public void setCardId(UUID cardId) { this.cardId = cardId; }
    public String getRating() { return rating; }
    public void setRating(String rating) { this.rating = rating; }
    public OffsetDateTime getRatedAt() { return ratedAt; }
    public void setRatedAt(OffsetDateTime ratedAt) { this.ratedAt = ratedAt; }
    public long getReviewVersion() { return reviewVersion; }
    public void setReviewVersion(long reviewVersion) { this.reviewVersion = reviewVersion; }
}
