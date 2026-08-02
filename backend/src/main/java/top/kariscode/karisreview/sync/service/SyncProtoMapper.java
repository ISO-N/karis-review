package top.kariscode.karisreview.sync.service;

import org.springframework.stereotype.Component;
import top.kariscode.karisreview.proto.KarisReviewProto;
import top.kariscode.karisreview.sync.dto.BootstrapCard;
import top.kariscode.karisreview.sync.dto.BootstrapDeck;
import top.kariscode.karisreview.sync.dto.BootstrapResponse;
import top.kariscode.karisreview.sync.dto.BootstrapReviewLog;
import top.kariscode.karisreview.sync.dto.BootstrapUser;

import java.time.format.DateTimeFormatter;

@Component
public class SyncProtoMapper {

    private static final DateTimeFormatter ISO_DATE_TIME =
            DateTimeFormatter.ISO_LOCAL_DATE_TIME;

    public KarisReviewProto.SyncResponse toProto(BootstrapResponse response) {
        KarisReviewProto.SyncResponse.Builder builder = KarisReviewProto.SyncResponse.newBuilder()
                .setServerTime(response.getServerTime().format(DateTimeFormatter.ISO_OFFSET_DATE_TIME))
                .setUser(toUser(response.getUser()))
                .setEventCursor(response.getEventCursor())
                .setHasMore(response.isHasMore())
                .setResetRequired(response.isResetRequired());

        for (BootstrapDeck deck : response.getDecks()) {
            builder.addDecks(toDeck(deck));
        }
        for (BootstrapCard card : response.getChangedCards()) {
            builder.addChangedCards(toCard(card));
        }
        for (BootstrapReviewLog log : response.getReviewLogs()) {
            builder.addReviewLogs(toReviewLog(log));
        }
        builder.addAllDeletedDeckIds(response.getDeletedDeckIds());
        builder.addAllDeletedCardIds(response.getDeletedCardIds());
        builder.addAllDeletedReviewLogIds(response.getDeletedReviewLogIds());
        return builder.build();
    }

    private KarisReviewProto.User toUser(BootstrapUser user) {
        return KarisReviewProto.User.newBuilder()
                .setId(user.getId().toString())
                .setEmail(user.getEmail())
                .setRefreshTime(user.getRefreshTime())
                .build();
    }

    private KarisReviewProto.Deck toDeck(BootstrapDeck deck) {
        KarisReviewProto.Deck.Builder builder = KarisReviewProto.Deck.newBuilder()
                .setId(deck.getId().toString())
                .setName(deck.getName())
                .setCreatedAt(format(deck.getCreatedAt()))
                .setUpdatedAt(format(deck.getUpdatedAt()));
        for (BootstrapCard card : deck.getCards()) {
            builder.addCards(toCard(card));
        }
        return builder.build();
    }

    private KarisReviewProto.Card toCard(BootstrapCard card) {
        KarisReviewProto.Card.Builder builder = KarisReviewProto.Card.newBuilder()
                .setId(card.getId().toString())
                .setDeckId(card.getDeckId().toString())
                .setFront(card.getFront())
                .setBack(card.getBack())
                .setStage(card.getStage())
                .setConsecutiveFamiliar(card.getConsecutiveFamiliar())
                .setLearningMode(card.isLearningMode())
                .setLearningStep(card.getLearningStep())
                .setReviewVersion(card.getReviewVersion())
                .setCreatedAt(format(card.getCreatedAt()))
                .setUpdatedAt(format(card.getUpdatedAt()));
        if (card.getNextReviewDate() != null) {
            builder.setNextReviewDate(card.getNextReviewDate().toString());
        }
        if (card.getReentryStage() != null) {
            builder.setReentryStage(card.getReentryStage().toString());
        }
        return builder.build();
    }

    private KarisReviewProto.ReviewLog toReviewLog(BootstrapReviewLog log) {
        return KarisReviewProto.ReviewLog.newBuilder()
                .setId(log.getId().toString())
                .setCardId(log.getCardId().toString())
                .setRating(log.getRating())
                .setStageBefore(log.getStageBefore())
                .setStageAfter(log.getStageAfter())
                .setReviewedAt(format(log.getReviewedAt()))
                .setIsNewCard(log.isNewCard())
                .build();
    }

    private String format(java.time.LocalDateTime value) {
        return value == null ? "" : value.format(ISO_DATE_TIME);
    }
}
