package top.kariscode.karisreview.review.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import top.kariscode.karisreview.auth.entity.User;
import top.kariscode.karisreview.auth.repository.UserRepository;
import top.kariscode.karisreview.card.entity.Card;
import top.kariscode.karisreview.card.repository.CardRepository;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.common.util.DateUtils;
import top.kariscode.karisreview.review.dto.RateRequest;
import top.kariscode.karisreview.review.dto.RateResponse;
import top.kariscode.karisreview.review.dto.ReviewCardResponse;
import top.kariscode.karisreview.review.dto.ReviewSyncItem;
import top.kariscode.karisreview.review.dto.ReviewSyncRequest;
import top.kariscode.karisreview.review.dto.ReviewSyncResponse;
import top.kariscode.karisreview.review.entity.ReviewLog;
import top.kariscode.karisreview.review.repository.ReviewLogRepository;
import top.kariscode.karisreview.log.service.UserLogService;
import top.kariscode.karisreview.review.repository.ReviewQueueItemRepository;
import top.kariscode.karisreview.review.repository.ReviewSessionRepository;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.mockito.ArgumentCaptor;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ReviewServiceTest {

    @Mock
    private CardRepository cardRepository;

    @Mock
    private ReviewLogRepository reviewLogRepository;

    @Mock
    private UserRepository userRepository;

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
                cardRepository, reviewLogRepository, userRepository, schedulingEngine,
                reviewSessionRepository, reviewQueueItemRepository, userLogService);
    }

    @Test
    void getDueCardsInterleavesLearningCardsWithPowerOfTwoSpacing() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        Card dueA = card("A", deckId, userId, 2, false, 0);
        Card dueB = card("B", deckId, userId, 2, false, 0);
        Card dueC = card("C", deckId, userId, 2, false, 0);
        Card learning1 = card("L1", deckId, userId, 0, true, 0);
        Card learning2 = card("L2", deckId, userId, 0, true, 1);
        when(userRepository.findById(userId)).thenReturn(Optional.of(user()));
        when(cardRepository.findDueCards(userId, DateUtils.calculateToday(LocalTime.of(4, 0)), deckId))
                .thenReturn(List.of(dueA, dueB, dueC));
        when(cardRepository.findLearningModeCards(
                userId, DateUtils.calculateToday(LocalTime.of(4, 0)), deckId))
                .thenReturn(List.of(learning2, learning1));

        List<ReviewCardResponse> queue = service.getDueCards(userId, deckId);

        assertEquals(List.of("A", "L1", "L2", "B", "C"),
                queue.stream().map(ReviewCardResponse::getFront).toList());
    }

    @Test
    void getNewCardsReturnsAllNewCards() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        when(cardRepository.findNewCards(userId, deckId)).thenReturn(List.of(
                card("1", deckId, userId, 0, false, 0),
                card("2", deckId, userId, 0, false, 0),
                card("3", deckId, userId, 0, false, 0)));

        List<ReviewCardResponse> queue = service.getNewCards(userId, deckId);

        assertEquals(3, queue.size());
    }
    @Test
    void rateFamiliarSavesCardAndReviewLog() {
        UUID userId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        Card card = new Card();
        card.setId(cardId);
        card.setStage(0);
        when(cardRepository.findByIdAndUserIdForUpdate(cardId, userId)).thenReturn(Optional.of(card));
        when(userRepository.findById(userId)).thenReturn(Optional.of(user()));
        SchedulingEngine.RatingResult result = result(0, 1, false, 0);
        when(schedulingEngine.rateFamiliar(card, LocalTime.of(4, 0))).thenReturn(result);
        when(cardRepository.save(card)).thenReturn(card);

        RateResponse response = service.rateCard(userId, cardId, rate("FAMILIAR"));

        assertEquals(cardId, response.getCardId());
        assertEquals(1, response.getStageAfter());
        assertEquals(1, response.getNextIntervalDays());
        ArgumentCaptor<ReviewLog> captor = ArgumentCaptor.forClass(ReviewLog.class);
        verify(reviewLogRepository).save(captor.capture());
        assertTrue(captor.getValue().isNewCard());
    }

    @Test
    void rateForgetCreatesLearningLog() {
        UUID userId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        Card card = new Card();
        card.setId(cardId);
        card.setStage(4);
        when(cardRepository.findByIdAndUserIdForUpdate(cardId, userId)).thenReturn(Optional.of(card));
        when(userRepository.findById(userId)).thenReturn(Optional.of(user()));
        SchedulingEngine.RatingResult result = result(4, 0, true, 0);
        when(schedulingEngine.rateForget(card, LocalTime.of(4, 0))).thenReturn(result);
        when(cardRepository.save(card)).thenReturn(card);

        RateResponse response = service.rateCard(userId, cardId, rate("FORGET"));

        assertTrue(response.isLearningMode());
        assertEquals(0, response.getStageAfter());
        ArgumentCaptor<ReviewLog> captor = ArgumentCaptor.forClass(ReviewLog.class);
        verify(reviewLogRepository).save(captor.capture());
        assertTrue(!captor.getValue().isNewCard());
    }

    @Test
    void rateRejectsInvalidRating() {
        UUID userId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        Card card = new Card();
        card.setId(cardId);
        when(cardRepository.findByIdAndUserIdForUpdate(cardId, userId)).thenReturn(Optional.of(card));

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.rateCard(userId, cardId, rate("UNKNOWN")));

        assertEquals(400, exception.getCode());
        assertEquals("review.rating.invalid", exception.getMessage());
        verify(cardRepository, never()).save(any());
        verify(reviewLogRepository, never()).save(any());
    }

    @Test
    void rateRejectsMissingCard() {
        UUID userId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        when(cardRepository.findByIdAndUserIdForUpdate(cardId, userId)).thenReturn(Optional.empty());

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.rateCard(userId, cardId, rate("FAMILIAR")));

        assertEquals(404, exception.getCode());
        assertEquals("review.card.notfound", exception.getMessage());
    }

    @Test
    void syncRatingsRejectsVersionConflict() {
        UUID userId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        Card card = new Card();
        card.setId(cardId);
        card.setUserId(userId);
        card.setStage(3);
        card.setReviewVersion(3);
        when(cardRepository.findByIdAndUserIdForUpdate(cardId, userId)).thenReturn(Optional.of(card));

        ReviewSyncResponse response = service.syncRatings(userId, syncRequest(syncItem(cardId, 2)));

        assertEquals(1, response.getConflicts());
        assertEquals("CONFLICT", response.getItems().get(0).getStatus());
        assertNotNull(response.getItems().get(0).getCurrentCard());
        assertEquals(3, response.getItems().get(0).getCurrentCard().getStage());
        verify(cardRepository, never()).save(any());
        verify(reviewLogRepository, never()).save(any());
    }
    @Test
    void syncRatingsIsIdempotentForClientRequestId() {
        UUID userId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        ReviewLog existing = new ReviewLog();
        existing.setCardId(cardId);
        existing.setRating("FAMILIAR");
        when(reviewLogRepository.findByUserIdAndClientRequestId(userId, "request-1"))
                .thenReturn(Optional.of(existing));

        ReviewSyncResponse response = service.syncRatings(
                userId, syncRequest(syncItem(cardId, 0)));

        assertEquals("ALREADY_SYNCED", response.getItems().get(0).getStatus());
        verify(cardRepository, never()).findByIdAndUserIdForUpdate(any(), any());
        verify(reviewLogRepository, never()).save(any());
    }

    @Test
    void syncRatingsAppliesInOrderAndPersistsClientId() {
        UUID userId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        Card card = new Card();
        card.setId(cardId);
        card.setUserId(userId);
        card.setStage(0);
        card.setReviewVersion(0);
        when(cardRepository.findByIdAndUserIdForUpdate(cardId, userId)).thenReturn(Optional.of(card));
        when(userRepository.findById(userId)).thenReturn(Optional.of(user()));
        when(schedulingEngine.rateFamiliar(card, LocalTime.of(4, 0)))
                .thenReturn(result(0, 1, false, 0));
        when(cardRepository.save(card)).thenReturn(card);

        ReviewSyncResponse response = service.syncRatings(
                userId, syncRequest(syncItem(cardId, 0)));

        assertEquals(1, response.getSynced());
        assertEquals("SYNCED", response.getItems().get(0).getStatus());
        ArgumentCaptor<ReviewLog> captor = ArgumentCaptor.forClass(ReviewLog.class);
        verify(reviewLogRepository).save(captor.capture());
        assertEquals("request-1", captor.getValue().getClientRequestId());
        assertEquals(
                LocalDateTime.of(2025, 8, 2, 12, 0),
                captor.getValue().getReviewedAt());
    }

    @Test
    void rateCardRejectsStaleReviewVersion() {
        UUID userId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        Card card = new Card();
        card.setId(cardId);
        card.setUserId(userId);
        card.setReviewVersion(3);
        when(cardRepository.findByIdAndUserIdForUpdate(cardId, userId)).thenReturn(Optional.of(card));
        RateRequest request = rate("FAMILIAR");
        request.setReviewVersion(2);

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.rateCard(userId, cardId, request));

        assertEquals(409, exception.getCode());
        verify(cardRepository, never()).save(any());
        verify(reviewLogRepository, never()).save(any());
    }

    @Test
    void rateCardReturnsExistingResultForSameClientRequestId() {
        UUID userId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        ReviewLog existing = new ReviewLog();
        existing.setCardId(cardId);
        existing.setRating("FAMILIAR");
        existing.setStageBefore(2);
        existing.setStageAfter(3);
        Card current = new Card();
        current.setReviewVersion(5);
        when(reviewLogRepository.findByUserIdAndClientRequestId(userId, "request-1"))
                .thenReturn(Optional.of(existing));
        when(cardRepository.findByIdAndUserId(cardId, userId))
                .thenReturn(Optional.of(current));

        RateRequest request = rate("FAMILIAR");
        request.setClientRequestId("request-1");
        RateResponse response = service.rateCard(userId, cardId, request);

        assertEquals(3, response.getStageAfter());
        assertEquals(5, response.getReviewVersion());
        verify(cardRepository, never()).findByIdAndUserIdForUpdate(any(), any());
        verify(reviewLogRepository, never()).save(any());
    }

    @Test
    void rateCardRejectsSameClientRequestIdWithDifferentRating() {
        UUID userId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        ReviewLog existing = new ReviewLog();
        existing.setCardId(cardId);
        existing.setRating("FAMILIAR");
        when(reviewLogRepository.findByUserIdAndClientRequestId(userId, "request-1"))
                .thenReturn(Optional.of(existing));

        RateRequest request = rate("VAGUE");
        request.setClientRequestId("request-1");

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.rateCard(userId, cardId, request));

        assertEquals(409, exception.getCode());
        verify(cardRepository, never()).findByIdAndUserIdForUpdate(any(), any());
    }

    @Test
    void syncRatingsReturnsCardNotFound() {
        UUID userId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        when(cardRepository.findByIdAndUserIdForUpdate(cardId, userId))
                .thenReturn(Optional.empty());

        ReviewSyncResponse response = service.syncRatings(
                userId, syncRequest(syncItem(cardId, 0)));

        assertEquals(1, response.getMissing());
        assertEquals("CARD_NOT_FOUND", response.getItems().get(0).getStatus());
        verify(cardRepository, never()).save(any());
    }

    @Test
    void syncRatingsRejectsSameClientRequestIdWithDifferentPayload() {
        UUID userId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        ReviewLog existing = new ReviewLog();
        existing.setCardId(cardId);
        existing.setRating("FAMILIAR");
        when(reviewLogRepository.findByUserIdAndClientRequestId(userId, "request-1"))
                .thenReturn(Optional.of(existing));

        ReviewSyncItem item = syncItem(cardId, 0);
        item.setRating("VAGUE");
        ReviewSyncResponse response = service.syncRatings(userId, syncRequest(item));

        assertEquals(1, response.getConflicts());
        assertEquals("CONFLICT", response.getItems().get(0).getStatus());
        verify(cardRepository, never()).findByIdAndUserIdForUpdate(any(), any());
    }

    private ReviewSyncItem syncItem(UUID cardId, long reviewVersion) {
        ReviewSyncItem item = new ReviewSyncItem();
        item.setClientRequestId("request-1");
        item.setCardId(cardId);
        item.setRating("FAMILIAR");
        item.setRatedAt(OffsetDateTime.parse("2025-08-02T04:00:00Z"));
        return item;
    }

    private ReviewSyncRequest syncRequest(ReviewSyncItem item) {
        ReviewSyncRequest request = new ReviewSyncRequest();
        request.setItems(List.of(item));
        return request;
    }

    private User user() {
        return new User();
    }

    private Card card(String front, UUID deckId, UUID userId, int stage,
                      boolean learning, int learningStep) {
        Card card = new Card();
        card.setId(UUID.randomUUID());
        card.setDeckId(deckId);
        card.setUserId(userId);
        card.setFront(front);
        card.setBack("back");
        card.setStage(stage);
        card.setLearningMode(learning);
        card.setLearningStep(learningStep);
        return card;
    }

    private RateRequest rate(String rating) {
        RateRequest request = new RateRequest();
        request.setRating(rating);
        return request;
    }

    private SchedulingEngine.RatingResult result(int before, int after, boolean learning,
                                                 int consecutive) {
        SchedulingEngine.RatingResult result = new SchedulingEngine.RatingResult();
        result.setStageBefore(before);
        result.setStageAfter(after);
        result.setLearningMode(learning);
        result.setConsecutiveFamiliar(consecutive);
        result.setNextReviewDate(DateUtils.calculateToday(LocalTime.of(4, 0)).plusDays(1));
        return result;
    }
}
