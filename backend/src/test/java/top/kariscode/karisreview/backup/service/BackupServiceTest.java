package top.kariscode.karisreview.backup.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.ArgumentCaptor;
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
import top.kariscode.karisreview.log.service.UserLogService;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;

import static org.junit.jupiter.api.Assertions.assertNotEquals;
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
    @Mock
    private UserLogService userLogService;


    @BeforeEach
    void setUp() {
        service = new BackupService(
                userRepository, deckRepository, cardRepository,
                reviewLogRepository, backupRepository, objectMapper, userLogService);
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
        log.setNewCard(true);
        log.setReviewedAt(LocalDateTime.of(2025, 1, 1, 10, 0));

        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(deckRepository.findByUserIdOrderByCreatedAtAsc(userId)).thenReturn(List.of(deck));
        when(cardRepository.findByDeckIdOrderByCreatedAtAsc(deckId)).thenReturn(List.of(card));
        when(reviewLogRepository.findByUserIdOrderByReviewedAtDesc(userId)).thenReturn(List.of(log));
        when(cardRepository.findAllById(any())).thenReturn(List.of(card));
        when(backupRepository.save(any(BackupSnapshot.class))).thenAnswer(invocation -> {
            BackupSnapshot snapshot = invocation.getArgument(0);
            snapshot.setId(UUID.randomUUID());
            ReflectionTestUtils.setField(snapshot, "createdAt", LocalDateTime.of(2025, 1, 1, 11, 0));
            return snapshot;
        });

        Map<String, Object> result = service.exportData(userId);

        assertNotNull(result.get("backup_id"));
        assertTrue(result.toString().contains(user.getEmail()));
        assertTrue(result.toString().contains("is_new_card"));
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
        when(deckRepository.save(any(Deck.class))).thenAnswer(invocation -> {
            Deck deck = invocation.getArgument(0);
            deck.setId(UUID.randomUUID());
            return deck;
        });
        when(cardRepository.saveAll(any())).thenAnswer(invocation -> {
            List<Card> cards = invocation.getArgument(0);
            cards.forEach(c -> c.setId(UUID.randomUUID()));
            return cards;
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
                        "is_new_card", true,
                        "reviewed_at", "2025-01-01T10:00:00")));

        Map<String, Object> result = service.importData(userId, data);

        assertEquals(1, result.get("imported_decks"));
        assertEquals(1, result.get("imported_cards"));
        assertEquals(1, result.get("imported_review_logs"));
        ArgumentCaptor<List<ReviewLog>> logCaptor = ArgumentCaptor.forClass(List.class);
        verify(reviewLogRepository).saveAll(logCaptor.capture());
        assertEquals(true, logCaptor.getValue().get(0).isNewCard());
        verify(deckRepository).deleteAllByUserId(userId);
    }

    @Test
    void importDataMatchesLogByFrontFallback() {
        UUID userId = UUID.randomUUID();
        when(deckRepository.save(any(Deck.class))).thenAnswer(invocation -> {
            Deck deck = invocation.getArgument(0);
            deck.setId(UUID.randomUUID());
            return deck;
        });
        when(cardRepository.saveAll(any())).thenAnswer(invocation -> {
            List<Card> cards = invocation.getArgument(0);
            cards.forEach(c -> c.setId(UUID.randomUUID()));
            return cards;
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
        ArgumentCaptor<List<ReviewLog>> logCaptor = ArgumentCaptor.forClass(List.class);
        verify(reviewLogRepository).saveAll(logCaptor.capture());
        assertEquals(false, logCaptor.getValue().get(0).isNewCard());
    }

    @Test
    void importDataDirectlyReattachesLogByCardIdEvenWithDuplicateFront() {
        // 架构评审 B4：导出携带 card_id 后，同 front 多卡也能直连恢复，
        // 不再依赖 front 文本猜测（此前会错挂第一张匹配卡）。
        UUID userId = UUID.randomUUID();
        String backupCardIdA = UUID.randomUUID().toString();
        String backupCardIdB = UUID.randomUUID().toString();
        when(deckRepository.save(any(Deck.class))).thenAnswer(invocation -> {
            Deck deck = invocation.getArgument(0);
            deck.setId(UUID.randomUUID());
            return deck;
        });
        when(cardRepository.saveAll(any())).thenAnswer(invocation -> {
            List<Card> cards = invocation.getArgument(0);
            cards.forEach(c -> c.setId(UUID.randomUUID()));
            return cards;
        });

        // 两张卡 front 完全相同（重复 front 场景），日志只挂卡 B。
        Map<String, Object> data = Map.of(
                "decks", List.of(Map.of(
                        "name", "牌组",
                        "cards", List.of(
                                Map.of("id", backupCardIdA, "front", "重复正面", "back", "A"),
                                Map.of("id", backupCardIdB, "front", "重复正面", "back", "B")))),
                "review_logs", List.of(Map.of(
                        "card_id", backupCardIdB,
                        "card_front", "重复正面",
                        "rating", "FORGET",
                        "stage_before", 3,
                        "stage_after", 0)));

        Map<String, Object> result = service.importData(userId, data);

        assertEquals(2, result.get("imported_cards"));
        assertEquals(1, result.get("imported_review_logs"));
        ArgumentCaptor<List<ReviewLog>> logCaptor = ArgumentCaptor.forClass(List.class);
        verify(reviewLogRepository).saveAll(logCaptor.capture());
        // 直连挂到 B 卡（第二条导入卡），而非 front 匹配的第一张 A。
        assertNotEquals(backupCardIdA, logCaptor.getValue().get(0).getCardId().toString());
    }

    @Test
    void importDataIgnoresMissingDecksAndLogsWithoutError() {
        UUID userId = UUID.randomUUID();

        Map<String, Object> result = service.importData(userId, Map.of());

        assertEquals(0, result.get("imported_decks"));
        assertEquals(0, result.get("imported_cards"));
        assertEquals(0, result.get("imported_review_logs"));
        verify(cardRepository, never()).saveAll(any());
    }

    @Test
    void importDataDoesNotImportLogWithoutMatchingCard() {
        UUID userId = UUID.randomUUID();
        when(deckRepository.save(any(Deck.class))).thenAnswer(invocation -> {
            Deck deck = invocation.getArgument(0);
            deck.setId(UUID.randomUUID());
            return deck;
        });
        when(cardRepository.saveAll(any())).thenAnswer(invocation -> {
            List<Card> cards = invocation.getArgument(0);
            cards.forEach(c -> c.setId(UUID.randomUUID()));
            return cards;
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

    @Test
    void exportDataIncludesFullSchedulingState() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        User user = new User();
        user.setId(userId);
        user.setEmail("user@example.com");
        user.setRefreshTime(LocalTime.of(4, 0));
        Deck deck = new Deck();
        deck.setId(deckId);
        deck.setUserId(userId);
        deck.setName("日语");
        Card card = new Card();
        card.setId(UUID.randomUUID());
        card.setDeckId(deckId);
        card.setFront("正面");
        card.setBack("反面");
        card.setStage(3);
        card.setConsecutiveFamiliar(2);
        card.setNextReviewDate(java.time.LocalDate.of(2026, 8, 9));
        card.setLearningMode(true);
        card.setReentryStage(1);
        card.setLearningStep(2);
        card.setLearningOrigin("NEW");
        card.setReviewVersion(7);

        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(deckRepository.findByUserIdOrderByCreatedAtAsc(userId)).thenReturn(List.of(deck));
        when(cardRepository.findByDeckIdOrderByCreatedAtAsc(deckId)).thenReturn(List.of(card));
        when(reviewLogRepository.findByUserIdOrderByReviewedAtDesc(userId)).thenReturn(List.of());
        when(backupRepository.save(any(BackupSnapshot.class))).thenAnswer(invocation -> {
            BackupSnapshot snapshot = invocation.getArgument(0);
            snapshot.setId(UUID.randomUUID());
            ReflectionTestUtils.setField(snapshot, "createdAt", LocalDateTime.of(2026, 8, 8, 11, 0));
            return snapshot;
        });

        service.exportData(userId);

        ArgumentCaptor<BackupSnapshot> snapshotCaptor =
                ArgumentCaptor.forClass(BackupSnapshot.class);
        verify(backupRepository).save(snapshotCaptor.capture());
        String data = snapshotCaptor.getValue().getData();
        // 回归：曾漏导出 learning_step/learning_origin/review_version，
        // 恢复后队列归属退化与重学插位丢失（架构评审候选 2）。
        assertTrue(data.contains("\"learning_step\":2"), data);
        assertTrue(data.contains("\"learning_origin\":\"NEW\""), data);
        assertTrue(data.contains("\"review_version\":7"), data);
        assertTrue(data.contains("\"learning_mode\":true"), data);
        assertTrue(data.contains("\"reentry_stage\":1"), data);
        // 架构评审 B4：导出携带 card_id，导入可直连恢复（此前只写 front 文本）。
        assertTrue(data.contains("\"id\":\"" + card.getId() + "\""), data);
    }

    @Test
    void importDataRestoresSchedulingState() {
        UUID userId = UUID.randomUUID();
        when(deckRepository.save(any(Deck.class))).thenAnswer(invocation -> {
            Deck deck = invocation.getArgument(0);
            deck.setId(UUID.randomUUID());
            return deck;
        });
        when(cardRepository.saveAll(any())).thenAnswer(invocation -> {
            List<Card> cards = invocation.getArgument(0);
            cards.forEach(c -> c.setId(UUID.randomUUID()));
            return cards;
        });

        Map<String, Object> data = Map.of(
                "decks", List.of(Map.of(
                        "name", "恢复牌组",
                        "cards", List.of(Map.of(
                                "front", "正面",
                                "back", "反面",
                                "stage", 3,
                                "consecutive_familiar", 2,
                                "next_review_date", "2026-08-09",
                                "learning_mode", true,
                                "reentry_stage", 1,
                                "learning_step", 2,
                                "learning_origin", "NEW",
                                "review_version", 7)))));

        service.importData(userId, data);

        ArgumentCaptor<List<Card>> cardCaptor = ArgumentCaptor.forClass(List.class);
        verify(cardRepository).saveAll(cardCaptor.capture());
        Card restored = cardCaptor.getValue().get(0);
        // 排期状态整体恢复（架构评审候选 2）
        assertEquals(3, restored.getStage());
        assertEquals(2, restored.getConsecutiveFamiliar());
        assertEquals(java.time.LocalDate.of(2026, 8, 9), restored.getNextReviewDate());
        assertEquals(true, restored.isLearningMode());
        assertEquals(1, restored.getReentryStage());
        assertEquals(2, restored.getLearningStep());
        assertEquals("NEW", restored.getLearningOrigin());
        assertEquals(7, restored.getReviewVersion());
    }

    @Test
    void cleanupOldSnapshotsKeepsLatestPerUser() {
        when(backupRepository.deleteExcessSnapshots(7)).thenReturn(4);

        service.cleanupOldSnapshots();

        verify(backupRepository).deleteExcessSnapshots(7);
    }
}
