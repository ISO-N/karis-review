package top.kariscode.karisreview.common.etag;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalTime;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserEtagServiceTest {

    @Mock
    private SyncEventSeqQuery syncEventSeqQuery;

    @Mock
    private UserRefreshTimeQuery userRefreshTimeQuery;

    private UserEtagService service;

    @BeforeEach
    void setUp() {
        service = new UserEtagService(syncEventSeqQuery, userRefreshTimeQuery);
        lenient().when(userRefreshTimeQuery.resolve(any(UUID.class)))
                .thenReturn(LocalTime.of(4, 0));
    }

    @Test
    void etagChangesWhenEventSequenceChanges() {
        UUID userId = UUID.randomUUID();
        when(syncEventSeqQuery.latestSeq(userId)).thenReturn(1L);
        String first = service.decksEtag(userId);

        when(syncEventSeqQuery.latestSeq(userId)).thenReturn(2L);
        String second = service.decksEtag(userId);

        assertNotEquals(first, second);
        assertTrue(first.startsWith("W/\"karis-review-api-v1-decks-1-"));
    }

    @Test
    void deckStatsEtagIncludesDeckId() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        when(syncEventSeqQuery.latestSeq(userId)).thenReturn(3L);

        String etag = service.deckStatsEtag(userId, deckId);

        assertTrue(etag.contains("deck-stats"));
        assertTrue(etag.endsWith("-" + deckId + "\""));
    }

    @Test
    void overviewEtagHasNoDeckSuffix() {
        UUID userId = UUID.randomUUID();
        when(syncEventSeqQuery.latestSeq(userId)).thenReturn(0L);

        String etag = service.overviewEtag(userId);

        assertTrue(etag.contains("-overview-0-"));
        assertTrue(etag.endsWith("\""));
    }
}
