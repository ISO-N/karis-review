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
import top.kariscode.karisreview.review.entity.ReviewLog;
import top.kariscode.karisreview.review.repository.ReviewLogRepository;

import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
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

    private ReviewService service;

    @BeforeEach
    void setUp() {
        service = new ReviewService(
                cardRepository, reviewLogRepository, userRepository, schedulingEngine);
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
    void getNewCardsRespectsLimit() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        when(cardRepository.findNewCards(userId, deckId)).thenReturn(List.of(
                card("1", deckId, userId, 0, false, 0),
                card("2", deckId, userId, 0, false, 0),
                card("3", deckId, userId, 0, false, 0)));

        List<ReviewCardResponse> queue = service.getNewCards(userId, deckId, 2);

        assertEquals(2, queue.size());
    }

    @Test
    void rateFamiliarSavesCardAndReviewLog() {
        UUID userId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        Card card = new Card();
        card.setId(cardId);
        card.setStage(0);
        when(cardRepository.findByIdAndUserId(cardId, userId)).thenReturn(Optional.of(card));
        when(userRepository.findById(userId)).thenReturn(Optional.of(user()));
        SchedulingEngine.RatingResult result = result(0, 1, false, 0);
        when(schedulingEngine.rateFamiliar(card, LocalTime.of(4, 0))).thenReturn(result);
        when(cardRepository.save(card)).thenReturn(card);

        RateResponse response = service.rateCard(userId, cardId, rate("FAMILIAR"));

        assertEquals(cardId, response.getCardId());
        assertEquals(1, response.getStageAfter());
        assertEquals(1, response.getNextIntervalDays());
        verify(reviewLogRepository).save(any(ReviewLog.class));
    }

    @Test
    void rateForgetCreatesLearningLog() {
        UUID userId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        Card card = new Card();
        card.setId(cardId);
        card.setStage(4);
        when(cardRepository.findByIdAndUserId(cardId, userId)).thenReturn(Optional.of(card));
        when(userRepository.findById(userId)).thenReturn(Optional.of(user()));
        SchedulingEngine.RatingResult result = result(4, 0, true, 0);
        when(schedulingEngine.rateForget(card, LocalTime.of(4, 0))).thenReturn(result);
        when(cardRepository.save(card)).thenReturn(card);

        RateResponse response = service.rateCard(userId, cardId, rate("FORGET"));

        assertTrue(response.isLearningMode());
        assertEquals(0, response.getStageAfter());
    }

    @Test
    void rateRejectsInvalidRating() {
        UUID userId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        Card card = new Card();
        card.setId(cardId);
        when(cardRepository.findByIdAndUserId(cardId, userId)).thenReturn(Optional.of(card));

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.rateCard(userId, cardId, rate("UNKNOWN")));

        assertEquals(400, exception.getCode());
        assertEquals("无效的评分", exception.getMessage());
        verify(cardRepository, never()).save(any());
        verify(reviewLogRepository, never()).save(any());
    }

    @Test
    void rateRejectsMissingCard() {
        UUID userId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        when(cardRepository.findByIdAndUserId(cardId, userId)).thenReturn(Optional.empty());

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.rateCard(userId, cardId, rate("FAMILIAR")));

        assertEquals(404, exception.getCode());
        assertEquals("卡片不存在", exception.getMessage());
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
