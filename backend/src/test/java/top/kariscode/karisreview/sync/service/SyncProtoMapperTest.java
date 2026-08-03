package top.kariscode.karisreview.sync.service;

import org.junit.jupiter.api.Test;
import top.kariscode.karisreview.proto.KarisReviewProto;
import top.kariscode.karisreview.sync.dto.BootstrapCard;
import top.kariscode.karisreview.sync.dto.BootstrapDeck;
import top.kariscode.karisreview.sync.dto.BootstrapResponse;
import top.kariscode.karisreview.sync.dto.BootstrapReviewLog;
import top.kariscode.karisreview.sync.dto.BootstrapUser;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class SyncProtoMapperTest {

    private final SyncProtoMapper mapper = new SyncProtoMapper();

    @Test
    void toProtoMapsAllBootstrapFields() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        UUID logId = UUID.randomUUID();
        BootstrapCard card = new BootstrapCard(
                cardId, deckId, "正面", "反面",
                4, 2, LocalDate.of(2025, 8, 5), true, 4, 3,
                7L, LocalDateTime.of(2025, 8, 1, 10, 0),
                LocalDateTime.of(2025, 8, 2, 11, 0));
        BootstrapDeck deck = new BootstrapDeck(
                deckId, "日语", LocalDateTime.of(2025, 8, 1, 10, 0),
                LocalDateTime.of(2025, 8, 2, 11, 0), List.of(card));
        BootstrapReviewLog log = new BootstrapReviewLog(
                logId, cardId, "FAMILIAR", 4, 4,
                LocalDateTime.of(2025, 8, 2, 12, 0), true, "request-1");
        BootstrapResponse response = new BootstrapResponse(
                OffsetDateTime.parse("2025-08-02T12:00:00Z"),
                new BootstrapUser(userId, "user@example.com", "04:00:00"),
                List.of(deck),
                List.of(log),
                List.of(card),
                List.of("deleted-deck"),
                List.of("deleted-card"),
                List.of("deleted-log"),
                99L,
                true,
                true);

        KarisReviewProto.SyncResponse proto = mapper.toProto(response);

        assertEquals("2025-08-02T12:00:00Z", proto.getServerTime());
        assertEquals(userId.toString(), proto.getUser().getId());
        assertEquals(deckId.toString(), proto.getDecks(0).getId());
        assertEquals(cardId.toString(), proto.getDecks(0).getCards(0).getId());
        assertEquals("4", proto.getDecks(0).getCards(0).getReentryStage());
        assertEquals(logId.toString(), proto.getReviewLogs(0).getId());
        assertEquals("request-1", proto.getReviewLogs(0).getClientRequestId());
        assertEquals(1, proto.getChangedCardsCount());
        assertEquals(List.of("deleted-deck"), proto.getDeletedDeckIdsList());
        assertEquals(List.of("deleted-card"), proto.getDeletedCardIdsList());
        assertEquals(List.of("deleted-log"), proto.getDeletedReviewLogIdsList());
        assertEquals(99L, proto.getEventCursor());
        assertTrue(proto.getHasMore());
        assertTrue(proto.getResetRequired());
    }

    @Test
    void toProtoOmitsOptionalFieldsWhenNull() {
        BootstrapResponse response = new BootstrapResponse(
                OffsetDateTime.now(ZoneOffset.UTC),
                new BootstrapUser(UUID.randomUUID(), "user@example.com", "04:00:00"),
                List.of(),
                List.of());

        KarisReviewProto.SyncResponse proto = mapper.toProto(response);

        assertEquals(0, proto.getDecksCount());
        assertEquals(0, proto.getReviewLogsCount());
        assertEquals(0, proto.getChangedCardsCount());
        assertEquals(0, proto.getDeletedDeckIdsCount());
        assertFalse(proto.getResetRequired());
    }
}
