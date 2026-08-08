package top.kariscode.karisreview.review.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Pageable;
import top.kariscode.karisreview.auth.entity.User;
import top.kariscode.karisreview.common.etag.UserRefreshTimeQuery;
import top.kariscode.karisreview.card.entity.Card;
import top.kariscode.karisreview.card.repository.CardRepository;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.common.util.DateUtils;
import top.kariscode.karisreview.log.service.UserLogService;
import top.kariscode.karisreview.review.dto.ReviewSessionCreateRequest;
import top.kariscode.karisreview.review.dto.ReviewSessionPageResponse;
import top.kariscode.karisreview.review.entity.ReviewQueueItem;
import top.kariscode.karisreview.review.entity.ReviewSession;
import top.kariscode.karisreview.review.repository.ReviewLogRepository;
import top.kariscode.karisreview.review.repository.ReviewQueueItemRepository;
import top.kariscode.karisreview.review.repository.ReviewSessionRepository;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ReviewSessionServiceTest {

    @Mock
    private CardRepository cardRepository;

    @Mock
    private ReviewLogRepository reviewLogRepository;

    @Mock
    private UserRefreshTimeQuery userRefreshTimeQuery;

    @Mock
    private SchedulingEngine schedulingEngine;

    @Mock
    private ReviewSessionRepository reviewSessionRepository;

    @Mock
    private ReviewQueueItemRepository reviewQueueItemRepository;

    @Mock
    private UserLogService userLogService;

    private ReviewService service;

    @BeforeEach
    void setUp() {
        service = new ReviewService(
                cardRepository, reviewLogRepository, userRefreshTimeQuery, schedulingEngine,
                reviewSessionRepository, reviewQueueItemRepository, userLogService);
    }

    @Test
    void createSessionClampsBatchSizeAndPersistsQueueItems() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        UUID sessionId = UUID.randomUUID();
        when(userRefreshTimeQuery.resolve(userId)).thenReturn(LocalTime.of(4, 0));
        when(cardRepository.findDueCards(eq(userId), any(LocalDate.class), eq(deckId)))
                .thenReturn(List.of());
        when(cardRepository.findLearningModeCardsForReview(eq(userId), any(LocalDate.class), eq(deckId)))
                .thenReturn(List.of());
        ReviewSession[] savedSessionHolder = new ReviewSession[1];
        when(reviewSessionRepository.save(any(ReviewSession.class))).thenAnswer(inv -> {
            ReviewSession session = inv.getArgument(0);
            session.setId(sessionId);
            session.setExpiresAt(DateUtils.now().plusHours(1));
            savedSessionHolder[0] = session;
            return session;
        });
        when(reviewQueueItemRepository.saveAll(any())).thenReturn(List.of());
        when(reviewSessionRepository.findByIdAndUserId(sessionId, userId))
                .thenAnswer(inv -> Optional.of(savedSessionHolder[0]));
        ReviewSessionCreateRequest request = new ReviewSessionCreateRequest();
        request.setMode("due");
        request.setDeckId(deckId);
        request.setBatchSize(99);

        ReviewSessionPageResponse response = service.createSession(userId, request);

        assertEquals(sessionId, response.getSessionId());
        assertEquals(50, response.getBatchSize());
        assertEquals(0, response.getTotal());
        assertTrue(response.getCards().isEmpty());
        verify(reviewSessionRepository).save(any(ReviewSession.class));
        verify(reviewQueueItemRepository).saveAll(any());
    }

    @Test
    void getSessionPageReturnsPageAndHasMore() {
        UUID userId = UUID.randomUUID();
        UUID sessionId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        ReviewSession session = session(sessionId, userId, 2);
        Card card = card(cardId, userId, 2);
        ReviewQueueItem item = queueItem(sessionId, userId, 0, cardId);
        when(reviewSessionRepository.findByIdAndUserId(sessionId, userId))
                .thenReturn(Optional.of(session));
        when(reviewQueueItemRepository.findBySessionIdAndPositionGreaterThanEqualOrderByPositionAsc(
                eq(sessionId), eq(0), any(Pageable.class)))
                .thenReturn(List.of(item));
        when(cardRepository.findAllById(any())).thenReturn(List.of(card));

        ReviewSessionPageResponse response = service.getSessionPage(userId, sessionId, 0, 1);

        assertEquals(1, response.getCards().size());
        assertEquals(1, response.getCursor());
        assertTrue(response.isHasMore());
        assertEquals(2, response.getTotal());
    }

    @Test
    void getSessionPageRejectsSessionOwnedByOtherUser() {
        UUID ownerId = UUID.randomUUID();
        UUID otherUserId = UUID.randomUUID();
        UUID sessionId = UUID.randomUUID();
        when(reviewSessionRepository.findByIdAndUserId(sessionId, otherUserId))
                .thenReturn(Optional.empty());

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.getSessionPage(otherUserId, sessionId, 0, 10));

        assertEquals(404, exception.getCode());
        assertEquals("review.session.notfound", exception.getMessage());
    }

    @Test
    void getSessionPageRejectsExpiredSession() {
        UUID userId = UUID.randomUUID();
        UUID sessionId = UUID.randomUUID();
        ReviewSession expired = session(sessionId, userId, 1);
        expired.setExpiresAt(DateUtils.now().minusMinutes(1));
        when(reviewSessionRepository.findByIdAndUserId(sessionId, userId))
                .thenReturn(Optional.of(expired));

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.getSessionPage(userId, sessionId, 0, 10));

        assertEquals(410, exception.getCode());
        assertEquals("review.session.expired", exception.getMessage());
    }

    @Test
    void deleteSessionDeletesOwnedSession() {
        UUID userId = UUID.randomUUID();
        UUID sessionId = UUID.randomUUID();
        ReviewSession session = session(sessionId, userId, 0);
        when(reviewSessionRepository.findByIdAndUserId(sessionId, userId))
                .thenReturn(Optional.of(session));

        service.deleteSession(userId, sessionId);

        verify(reviewSessionRepository).delete(session);
    }

    @Test
    void cleanupExpiredSessionsDeletesByNow() {
        service.cleanupExpiredSessions();

        verify(reviewSessionRepository).deleteExpired(any());
    }

    private ReviewSession session(UUID id, UUID userId, int totalCount) {
        ReviewSession session = new ReviewSession();
        session.setId(id);
        session.setUserId(userId);
        session.setMode("due");
        session.setBatchSize(10);
        session.setTotalCount(totalCount);
        session.setExpiresAt(DateUtils.now().plusHours(1));
        return session;
    }

    private ReviewQueueItem queueItem(UUID sessionId, UUID userId, int position, UUID cardId) {
        ReviewQueueItem item = new ReviewQueueItem();
        item.setSessionId(sessionId);
        item.setUserId(userId);
        item.setPosition(position);
        item.setCardId(cardId);
        return item;
    }

    private Card card(UUID id, UUID userId, int stage) {
        Card card = new Card();
        card.setId(id);
        card.setDeckId(UUID.randomUUID());
        card.setUserId(userId);
        card.setFront("正面");
        card.setBack("反面");
        card.setStage(stage);
        return card;
    }

    private User user() {
        User user = new User();
        user.setId(UUID.randomUUID());
        user.setRefreshTime(LocalTime.of(4, 0));
        return user;
    }
}
