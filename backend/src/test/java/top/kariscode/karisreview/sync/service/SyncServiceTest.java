package top.kariscode.karisreview.sync.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import top.kariscode.karisreview.auth.entity.User;
import top.kariscode.karisreview.auth.repository.UserRepository;
import top.kariscode.karisreview.card.entity.Card;
import top.kariscode.karisreview.card.repository.CardRepository;
import top.kariscode.karisreview.deck.entity.Deck;
import top.kariscode.karisreview.deck.repository.DeckRepository;
import top.kariscode.karisreview.review.entity.ReviewLog;
import top.kariscode.karisreview.review.repository.ReviewLogRepository;
import top.kariscode.karisreview.sync.dto.BootstrapResponse;
import top.kariscode.karisreview.sync.repository.SyncEventRepository;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SyncServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private DeckRepository deckRepository;

    @Mock
    private CardRepository cardRepository;

    @Mock
    private ReviewLogRepository reviewLogRepository;

    @Mock
    private SyncEventRepository syncEventRepository;

    private SyncService service;

    @BeforeEach
    void setUp() {
        service = new SyncService(
                userRepository, deckRepository, cardRepository,
                reviewLogRepository, syncEventRepository);
    }

    @Test
    void fullBootstrapReturnsNestedDecksCardsLogsAndLatestCursor() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        Card card = card(deckId, userId, "正面");
        Deck deck = deck(deckId, userId, "日语");
        ReviewLog log = reviewLog(userId, card.getId());
        when(userRepository.findById(userId)).thenReturn(Optional.of(user(userId)));
        when(deckRepository.findByUserIdOrderByCreatedAtAsc(userId)).thenReturn(List.of(deck));
        when(cardRepository.findByDeckIdOrderByCreatedAtAsc(deckId)).thenReturn(List.of(card));
        when(reviewLogRepository.findByUserIdOrderByReviewedAtDesc(userId)).thenReturn(List.of(log));
        when(syncEventRepository.latestSeq(userId)).thenReturn(42L);

        BootstrapResponse response = service.getBootstrap(userId, 0);

        assertEquals(1, response.getDecks().size());
        assertEquals(1, response.getDecks().get(0).getCards().size());
        assertEquals(1, response.getReviewLogs().size());
        assertEquals(42L, response.getEventCursor());
        assertFalse(response.isResetRequired());
    }

    @Test
    void deltaBootstrapReturnsChangedDeletedAndFiltersByUser() {
        UUID userId = UUID.randomUUID();
        UUID otherUserId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        UUID otherCardId = UUID.randomUUID();
        UUID logId = UUID.randomUUID();
        Deck changedDeck = deck(deckId, userId, "改名");
        Card changedCard = card(deckId, userId, "新正面");
        Card otherCard = card(deckId, otherUserId, "他人");
        ReviewLog newLog = reviewLog(userId, cardId);
        when(userRepository.findById(userId)).thenReturn(Optional.of(user(userId)));
        when(syncEventRepository.latestSeq(userId)).thenReturn(30L);
        when(syncEventRepository.findAfter(userId, 10L, 500)).thenReturn(List.of(
                new SyncEventRepository.SyncEventRow("decks", deckId, "UPDATED", 11L),
                new SyncEventRepository.SyncEventRow("cards", cardId, "UPDATED", 12L),
                new SyncEventRepository.SyncEventRow("cards", cardId, "DELETED", 13L),
                new SyncEventRepository.SyncEventRow("review_logs", logId, "CREATED", 14L),
                new SyncEventRepository.SyncEventRow("review_logs", logId, "DELETED", 15L),
                new SyncEventRepository.SyncEventRow("users", userId, "UPDATED", 16L)));
        when(deckRepository.findByIdAndUserId(deckId, userId)).thenReturn(Optional.of(changedDeck));
        when(cardRepository.findAllById(any())).thenReturn(List.of(changedCard, otherCard));
        when(reviewLogRepository.findAllById(any())).thenReturn(List.of(newLog));

        BootstrapResponse response = service.getBootstrap(userId, 10L);

        assertEquals(1, response.getDecks().size());
        assertEquals(1, response.getChangedCards().size());
        assertEquals("新正面", response.getChangedCards().get(0).getFront());
        assertEquals(List.of(cardId.toString()), response.getDeletedCardIds());
        assertEquals(List.of(logId.toString()), response.getDeletedReviewLogIds());
        assertEquals(16L, response.getEventCursor());
        assertFalse(response.isHasMore());
    }
    @Test
    void deltaBootstrapReturnsLatestCursorWhenNoEvents() {
        UUID userId = UUID.randomUUID();
        when(userRepository.findById(userId)).thenReturn(Optional.of(user(userId)));
        when(syncEventRepository.latestSeq(userId)).thenReturn(30L);
        when(syncEventRepository.findAfter(userId, 30L, 500)).thenReturn(List.of());

        BootstrapResponse response = service.getBootstrap(userId, 30L);

        assertEquals(30L, response.getEventCursor());
        assertFalse(response.isHasMore());
        assertFalse(response.isResetRequired());
    }

    @Test
    void deltaBootstrapMarksHasMoreWhenPageIsFull() {
        UUID userId = UUID.randomUUID();
        List<SyncEventRepository.SyncEventRow> rows = new ArrayList<>();
        for (int i = 1; i <= 500; i++) {
            rows.add(new SyncEventRepository.SyncEventRow(
                    "users", userId, "UPDATED", 100L + i));
        }
        when(userRepository.findById(userId)).thenReturn(Optional.of(user(userId)));
        when(syncEventRepository.latestSeq(userId)).thenReturn(700L);
        when(syncEventRepository.findAfter(userId, 100L, 500)).thenReturn(rows);

        BootstrapResponse response = service.getBootstrap(userId, 100L);

        assertTrue(response.isHasMore());
        assertEquals(600L, response.getEventCursor());
    }

    @Test
    void staleCursorRequiresFullReset() {
        UUID userId = UUID.randomUUID();
        when(userRepository.findById(userId)).thenReturn(Optional.of(user(userId)));
        when(syncEventRepository.latestSeq(userId)).thenReturn(30L);

        BootstrapResponse response = service.getBootstrap(userId, 50L);

        assertTrue(response.isResetRequired());
        assertEquals(30L, response.getEventCursor());
        assertFalse(response.isHasMore());
        verify(syncEventRepository, never()).findAfter(eq(userId), anyLong(), anyInt());
    }

    private User user(UUID id) {
        User user = new User();
        user.setId(id);
        user.setEmail("user@example.com");
        user.setRefreshTime(LocalTime.of(4, 0));
        return user;
    }

    private Deck deck(UUID id, UUID userId, String name) {
        Deck deck = new Deck();
        deck.setId(id);
        deck.setUserId(userId);
        deck.setName(name);
        return deck;
    }

    private Card card(UUID deckId, UUID userId, String front) {
        Card card = new Card();
        card.setId(UUID.randomUUID());
        card.setDeckId(deckId);
        card.setUserId(userId);
        card.setFront(front);
        card.setBack("反面");
        return card;
    }

    private ReviewLog reviewLog(UUID userId, UUID cardId) {
        ReviewLog log = new ReviewLog();
        log.setId(UUID.randomUUID());
        log.setUserId(userId);
        log.setCardId(cardId);
        log.setRating("FAMILIAR");
        log.setStageBefore(0);
        log.setStageAfter(1);
        log.setNewCard(true);
        log.setReviewedAt(LocalDateTime.of(2025, 8, 2, 12, 0));
        return log;
    }
}
