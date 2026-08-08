package top.kariscode.karisreview.review.service;

import org.springframework.stereotype.Component;
import top.kariscode.karisreview.config.AppTimeZone;
import top.kariscode.karisreview.proto.KarisReviewProto;
import top.kariscode.karisreview.review.dto.ReviewCardResponse;
import top.kariscode.karisreview.review.dto.ReviewSessionCreateRequest;
import top.kariscode.karisreview.review.dto.ReviewSessionPageResponse;
import top.kariscode.karisreview.review.dto.ReviewSyncItem;
import top.kariscode.karisreview.review.dto.ReviewSyncItemResult;
import top.kariscode.karisreview.review.dto.ReviewSyncRequest;
import top.kariscode.karisreview.review.dto.ReviewSyncResponse;

import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.UUID;

@Component
public class ReviewProtoMapper {

    public ReviewSessionCreateRequest fromProto(
            KarisReviewProto.ReviewSessionCreateRequest proto) {
        ReviewSessionCreateRequest dto = new ReviewSessionCreateRequest();
        dto.setMode(proto.getMode());
        if (proto.hasDeckId() && !proto.getDeckId().isEmpty()) {
            dto.setDeckId(UUID.fromString(proto.getDeckId()));
        }
        dto.setBatchSize(proto.getBatchSize());
        return dto;
    }

    public KarisReviewProto.ReviewSessionCreateRequest toProto(
            ReviewSessionCreateRequest dto) {
        KarisReviewProto.ReviewSessionCreateRequest.Builder builder =
                KarisReviewProto.ReviewSessionCreateRequest.newBuilder()
                        .setMode(dto.getMode())
                        .setBatchSize(dto.getBatchSize() == null ? 10 : dto.getBatchSize());
        if (dto.getDeckId() != null) {
            builder.setDeckId(dto.getDeckId().toString());
        }
        return builder.build();
    }

    public KarisReviewProto.ReviewSessionPageResponse toProto(
            ReviewSessionPageResponse dto) {
        KarisReviewProto.ReviewSessionPageResponse.Builder builder =
                KarisReviewProto.ReviewSessionPageResponse.newBuilder()
                        .setSessionId(dto.getSessionId().toString())
                        .setMode(dto.getMode())
                        .setBatchSize(dto.getBatchSize())
                        .setTotal(dto.getTotal())
                        .setCursor(dto.getCursor())
                        .setHasMore(dto.isHasMore());
        if (dto.getDeckId() != null) {
            builder.setDeckId(dto.getDeckId().toString());
        }
        for (ReviewCardResponse card : dto.getCards()) {
            builder.addCards(toCard(card));
        }
        return builder.build();
    }

    public KarisReviewProto.ReviewCardListResponse toCardList(List<ReviewCardResponse> cards) {
        KarisReviewProto.ReviewCardListResponse.Builder builder =
                KarisReviewProto.ReviewCardListResponse.newBuilder();
        for (ReviewCardResponse card : cards) {
            builder.addCards(toCard(card));
        }
        return builder.build();
    }

    public ReviewSyncRequest fromProto(KarisReviewProto.ReviewSyncRequest proto) {
        ReviewSyncRequest dto = new ReviewSyncRequest();
        List<ReviewSyncItem> items = new java.util.ArrayList<>();
        for (KarisReviewProto.ReviewSyncItem item : proto.getItemsList()) {
            ReviewSyncItem syncItem = new ReviewSyncItem();
            syncItem.setClientRequestId(item.getClientRequestId());
            syncItem.setCardId(UUID.fromString(item.getCardId()));
            syncItem.setRating(item.getRating());
            syncItem.setRatedAt(parseRatedAt(item.getRatedAt()));
            syncItem.setReviewVersion(item.getReviewVersion());
            items.add(syncItem);
        }
        dto.setItems(items);
        return dto;
    }

    public KarisReviewProto.ReviewSyncResponse toProto(ReviewSyncResponse dto) {
        KarisReviewProto.ReviewSyncResponse.Builder builder =
                KarisReviewProto.ReviewSyncResponse.newBuilder()
                        .setSynced(dto.getSynced())
                        .setConflicts(dto.getConflicts())
                        .setMissing(dto.getMissing());
        for (ReviewSyncItemResult result : dto.getItems()) {
            KarisReviewProto.ReviewSyncItemResult.Builder resultBuilder =
                    KarisReviewProto.ReviewSyncItemResult.newBuilder()
                            .setClientRequestId(result.getClientRequestId())
                            .setStatus(result.getStatus());
            // card_id（架构评审 A4 补齐）：proto 早已声明，此前从不填充。
            if (result.getCardId() != null) {
                resultBuilder.setCardId(result.getCardId().toString());
            }
            if (result.getCurrentCard() != null) {
                resultBuilder.setCurrentCard(toCard(result.getCurrentCard()));
            }
            builder.addItems(resultBuilder);
        }
        return builder.build();
    }

    private KarisReviewProto.ReviewCard toCard(ReviewCardResponse card) {
        KarisReviewProto.ReviewCard.Builder builder = KarisReviewProto.ReviewCard.newBuilder()
                .setId(card.getId().toString())
                .setDeckId(card.getDeckId().toString())
                .setFront(card.getFront())
                .setBack(card.getBack() == null ? "" : card.getBack())
                .setStage(card.getStage())
                .setLearningMode(card.isLearningMode())
                .setConsecutiveFamiliar(card.getConsecutiveFamiliar())
                .setLearningStep(card.getLearningStep())
                .setReviewVersion(card.getReviewVersion());
        if (card.getReentryStage() != null) {
            builder.setReentryStage(card.getReentryStage().toString());
        }
        if (card.getNextReviewDate() != null) {
            builder.setNextReviewDate(card.getNextReviewDate().toString());
        }
        if (card.getLearningOrigin() != null) {
            builder.setLearningOrigin(card.getLearningOrigin());
        }
        return builder.build();
    }

    private static OffsetDateTime parseRatedAt(String value) {
        try {
            return OffsetDateTime.parse(value);
        } catch (DateTimeParseException ignored) {
            return LocalDateTime.parse(value).atZone(AppTimeZone.get()).toOffsetDateTime();
        }
    }
}
