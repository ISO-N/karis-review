package top.kariscode.karisreview.review.service;

import org.junit.jupiter.api.Test;
import top.kariscode.karisreview.config.AppTimeZone;
import top.kariscode.karisreview.proto.KarisReviewProto;
import top.kariscode.karisreview.review.dto.ReviewSyncItem;
import top.kariscode.karisreview.review.dto.ReviewSyncRequest;

import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;

class ReviewProtoMapperTest {

    private final ReviewProtoMapper mapper = new ReviewProtoMapper();

    @Test
    void fromProtoAcceptsUtcOffsetRatedAt() {
        ReviewSyncRequest request = mapper.fromProto(requestWithRatedAt(
                "2025-08-02T12:00:00Z"));

        ReviewSyncItem item = request.getItems().get(0);
        assertEquals(OffsetDateTime.parse("2025-08-02T12:00:00Z"), item.getRatedAt());
    }

    @Test
    void fromProtoKeepsNonUtcOffset() {
        ReviewSyncRequest request = mapper.fromProto(requestWithRatedAt(
                "2025-08-02T12:00:00+08:00"));

        ReviewSyncItem item = request.getItems().get(0);
        assertEquals(OffsetDateTime.parse("2025-08-02T12:00:00+08:00"), item.getRatedAt());
    }

    @Test
    void fromProtoStillAcceptsLegacyLocalDateTimeAsBusinessTime() {
        ReviewSyncRequest request = mapper.fromProto(requestWithRatedAt(
                "2025-08-02T12:00:00"));

        ReviewSyncItem item = request.getItems().get(0);
        assertEquals(
                LocalDateTime.parse("2025-08-02T12:00:00")
                        .atZone(AppTimeZone.get())
                        .toOffsetDateTime(),
                item.getRatedAt());
    }

    private KarisReviewProto.ReviewSyncRequest requestWithRatedAt(String ratedAt) {
        KarisReviewProto.ReviewSyncItem item = KarisReviewProto.ReviewSyncItem.newBuilder()
                .setClientRequestId("request-1")
                .setCardId(UUID.randomUUID().toString())
                .setRating("FAMILIAR")
                .setRatedAt(ratedAt)
                .setReviewVersion(0)
                .build();
        return KarisReviewProto.ReviewSyncRequest.newBuilder()
                .addItems(item)
                .build();
    }
}
