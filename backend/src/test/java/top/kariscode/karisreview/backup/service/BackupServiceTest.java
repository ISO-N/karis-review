package top.kariscode.karisreview.backup.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;
import top.kariscode.karisreview.backup.entity.BackupSnapshot;
import top.kariscode.karisreview.backup.repository.BackupRepository;
import top.kariscode.karisreview.auth.entity.User;
import top.kariscode.karisreview.auth.repository.UserRepository;
import top.kariscode.karisreview.card.entity.Card;
import top.kariscode.karisreview.card.repository.CardRepository;
import top.kariscode.karisreview.deck.entity.Deck;
import top.kariscode.karisreview.deck.repository.DeckRepository;
import top.kariscode.karisreview.review.entity.ReviewLog;
import top.kariscode.karisreview.review.repository.ReviewLogRepository;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class BackupServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private DeckRepository deckRepository;

    @Mock
    private CardRepository cardRepository;

    @Mock
    private ReviewLogRepository reviewLogRepository;

    @Mock
    private BackupRepository backupRepository;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private BackupService service;

    @BeforeEach
    void setUp() {
        service = new BackupService(
                userRepository, deckRepository, cardRepository,
                reviewLogRepository, backupRepository, objectMapper);
    }

    @Test
    void exportDataBuildsJsonAndSavesSnapshot() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        User user = new User();
        user.setId(userId);
        user.setEmail("user@example.com");
        user.setRefreshTime(LocalTime.of(4, 0));
        Deck deck = new Deck();
        deck.setId(deckId);
        deck.setUserId(userId);
        deck.setName("日语");
        Card card = new Card();
        card.setId(cardId);
        card.setDeckId(deckId);
        card.setFront("正面");
        card.setBack("反面");
        card.setStage(3);
        ReviewLog log = new ReviewLog();
        log.setCardId(cardId);
        log.setUserId(userId);
        log.setRating("FAMILIAR");
        log.setStageBefore(2);
        log.setStageAfter(3);
        log.setReviewedAt(LocalDateTime.of(2025, 1, 1, 10, 0));

        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(deckRepository.findByUserIdOrderByCreatedAtAsc(userId)).thenReturn(List.of(deck));
        when(cardRepository.findByDeckIdOrderByCreatedAtAsc(deckId)).thenReturn(List.of(card));
        when(reviewLogRepository.findByUserIdOrderByReviewedAtDesc(userId)).thenReturn(List.of(log));
        when(cardRepository.findById(cardId)).thenReturn(Optional.of(card));
        when(backupRepository.save(any(BackupSnapshot.class))).thenAnswer(invocation -> {
            BackupSnapshot snapshot = invocation.getArgument(0);
            snapshot.setId(UUID.randomUUID());
            ReflectionTestUtils.setField(snapshot, "createdAt", LocalDateTime.of(2025, 1, 1, 11, 0));
            return snapshot;
        });

        Map<String, Object> result = service.exportData(userId);

        assertNotNull(result.get("backup_id"));
        assertTrue(result.toString().contains(user.getEmail()));
        verify(backupRepository).save(any(BackupSnapshot.class));
    }

    @Test
    void exportDataRejectsMissingUser() {
        UUID userId = UUID.randomUUID();
        when(userRepository.findById(userId)).thenReturn(Optional.empty());

        assertThrows(RuntimeException.class, () -> service.exportData(userId));
    }

    @Test
    void importDataDeletesExistingDataAndRestoresDecksCardsLogs() {
        UUID userId = UUID.randomUUID();
        UUID existingDeckId = UUID.randomUUID();
        Deck existing = new Deck();
        existing.setId(existingDeckId);
        existing.setUserId(userId);
        when(deckRepository.findByUserIdOrderByCreatedAtAsc(userId)).thenReturn(List.of(existing));
        when(deckRepository.save(any(Deck.class))).thenAnswer(invocation -> {
            Deck deck = invocation.getArgument(0);
            deck.setId(UUID.randomUUID());
            return deck;
        });
        when(cardRepository.save(any(Card.class))).thenAnswer(invocation -> {
            Card card = invocation.getArgument(0);
            card.setId(UUID.randomUUID());
            return card;
        });

        Map<String, Object> data = Map.of(
                "decks", List.of(Map.of(
                        "name", "恢复牌组",
                        "cards", List.of(Map.of(
                                "front", "正面",
                                "back", "反面",
                                "stage", 3,
                                "consecutive_familiar", 1,
                                "next_review_date", "2025-01-02",
                                "learning_mode", false)))),
                "review_logs", List.of(Map.of(
                        "card_front", "正面",
                        "rating", "FAMILIAR",
                        "stage_before", 2,
                        "stage_after", 3,
                        "reviewed_at", "2025-01-01T10:00:00")));

        Map<String, Object> result = service.importData(userId, data);

        assertEquals(1, result.get("imported_decks"));
        assertEquals(1, result.get("imported_cards"));
        assertEquals(1, result.get("imported_review_logs"));
        verify(deckRepository).delete(existing);
    }

    @Test
    void importDataMatchesLogByFrontFallback() {
        UUID userId = UUID.randomUUID();
        when(deckRepository.findByUserIdOrderByCreatedAtAsc(userId)).thenReturn(List.of());
        when(deckRepository.save(any(Deck.class))).thenAnswer(invocation -> {
            Deck deck = invocation.getArgument(0);
            deck.setId(UUID.randomUUID());
            return deck;
        });
        when(cardRepository.save(any(Card.class))).thenAnswer(invocation -> {
            Card card = invocation.getArgument(0);
            card.setId(UUID.randomUUID());
            return card;
        });

        Map<String, Object> data = Map.of(
                "decks", List.of(Map.of(
                        "name", "牌组",
                        "cards", List.of(Map.of("front", "唯一正面", "back", "反面")))),
                "review_logs", List.of(Map.of(
                        "card_front", "唯一正面",
                        "rating", "VAGUE",
                        "stage_before", 4,
                        "stage_after", 3)));

        Map<String, Object> result = service.importData(userId, data);

        assertEquals(1, result.get("imported_review_logs"));
    }

    @Test
    void importDataIgnoresMissingDecksAndLogsWithoutError() {
        UUID userId = UUID.randomUUID();
        when(deckRepository.findByUserIdOrderByCreatedAtAsc(userId)).thenReturn(List.of());

        Map<String, Object> result = service.importData(userId, Map.of());

        assertEquals(0, result.get("imported_decks"));
        assertEquals(0, result.get("imported_cards"));
        assertEquals(0, result.get("imported_review_logs"));
        verify(cardRepository, never()).save(any());
    }

    @Test
    void importDataDoesNotImportLogWithoutMatchingCard() {
        UUID userId = UUID.randomUUID();
        when(deckRepository.findByUserIdOrderByCreatedAtAsc(userId)).thenReturn(List.of());
        when(deckRepository.save(any(Deck.class))).thenAnswer(invocation -> {
            Deck deck = invocation.getArgument(0);
            deck.setId(UUID.randomUUID());
            return deck;
        });
        when(cardRepository.save(any(Card.class))).thenAnswer(invocation -> {
            Card card = invocation.getArgument(0);
            card.setId(UUID.randomUUID());
            return card;
        });

        Map<String, Object> data = Map.of(
                "decks", List.of(Map.of(
                        "name", "牌组",
                        "cards", List.of(Map.of("front", "A", "back", "B")))),
                "review_logs", List.of(Map.of("card_front", "不存在的卡")));

        Map<String, Object> result = service.importData(userId, data);

        assertEquals(1, result.get("imported_cards"));
        assertEquals(0, result.get("imported_review_logs"));
    }
}
