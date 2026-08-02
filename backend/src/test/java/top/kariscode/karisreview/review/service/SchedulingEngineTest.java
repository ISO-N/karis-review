package top.kariscode.karisreview.review.service;

import org.junit.jupiter.api.Test;
import top.kariscode.karisreview.card.entity.Card;
import top.kariscode.karisreview.common.util.DateUtils;

import java.time.LocalTime;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class SchedulingEngineTest {

    private final SchedulingEngine engine = new SchedulingEngine();
    private final LocalTime refreshTime = LocalTime.of(4, 0);

    @Test
    void familiarOnNewCardMovesToStageOneTomorrow() {
        Card card = new Card();
        card.setStage(0);

        SchedulingEngine.RatingResult result = engine.rateFamiliar(card, refreshTime);

        assertEquals(0, result.getStageBefore());
        assertEquals(1, result.getStageAfter());
        assertFalse(result.isLearningMode());
        assertEquals(DateUtils.calculateToday(refreshTime).plusDays(1), result.getNextReviewDate());
        assertEquals(1, card.getStage());
    }

    @Test
    void familiarAdvancesThroughStagesWithCorrectIntervals() {
        Card card = new Card();
        card.setStage(3);

        SchedulingEngine.RatingResult result = engine.rateFamiliar(card, refreshTime);

        assertEquals(4, result.getStageAfter());
        assertEquals(DateUtils.calculateToday(refreshTime).plusDays(7), result.getNextReviewDate());
    }

    @Test
    void familiarAtMaxStageDoesNotGoBeyondStageEight() {
        Card card = new Card();
        card.setStage(8);

        SchedulingEngine.RatingResult result = engine.rateFamiliar(card, refreshTime);

        assertEquals(8, result.getStageAfter());
        assertEquals(8, card.getStage());
        assertEquals(DateUtils.calculateToday(refreshTime).plusDays(180), result.getNextReviewDate());
        assertFalse(result.isLearningMode());
        assertEquals(0, result.getConsecutiveFamiliar());
    }

    @Test
    void intervalHelpersReportRatingTargetsForNormalAndRelearningCards() {
        Card normal = new Card();
        normal.setStage(3);
        assertEquals(4, SchedulingEngine.getStageInterval(3));
        assertEquals(7, SchedulingEngine.getFamiliarIntervalAfterRating(normal));
        assertEquals(4, SchedulingEngine.getVagueIntervalAfterRating(normal));

        Card relearning = new Card();
        relearning.setStage(0);
        relearning.setLearningMode(true);
        relearning.setConsecutiveFamiliar(2);
        relearning.setReentryStage(4);
        assertEquals(3, SchedulingEngine.getRelearningThreshold(relearning));
        assertEquals(3, SchedulingEngine.getFamiliarIntervalAfterRating(relearning));

        relearning.setConsecutiveFamiliar(1);
        assertEquals(0, SchedulingEngine.getFamiliarIntervalAfterRating(relearning));
    }

    @Test
    void forgetEntersRelearningModeAndResetsToStageZero() {
        Card card = new Card();
        card.setStage(4);
        card.setNextReviewDate(DateUtils.calculateToday(refreshTime).plusDays(7));

        SchedulingEngine.RatingResult result = engine.rateForget(card, refreshTime);

        assertEquals(0, result.getStageAfter());
        assertTrue(result.isLearningMode());
        assertTrue(card.isLearningMode());
        assertEquals(0, card.getConsecutiveFamiliar());
        assertEquals(0, card.getLearningStep());
        assertEquals(DateUtils.calculateToday(refreshTime), result.getNextReviewDate());
    }

    @Test
    void forgetOnStageZeroStaysInLearningModeWithoutDowngrade() {
        Card card = new Card();
        card.setStage(0);

        SchedulingEngine.RatingResult result = engine.rateForget(card, refreshTime);

        assertEquals(0, result.getStageBefore());
        assertEquals(0, result.getStageAfter());
        assertTrue(result.isLearningMode());
        assertNull(card.getReentryStage());
    }

    @Test
    void vagueStepsBackAndRequiresThreeFamiliarRatings() {
        Card card = new Card();
        card.setStage(4);

        SchedulingEngine.RatingResult vagueResult = engine.rateVague(card, refreshTime);

        assertEquals(3, vagueResult.getStageAfter());
        assertTrue(vagueResult.isLearningMode());
        assertEquals(4, card.getReentryStage());

        engine.rateFamiliar(card, refreshTime);
        engine.rateFamiliar(card, refreshTime);
        SchedulingEngine.RatingResult finalResult = engine.rateFamiliar(card, refreshTime);

        assertFalse(finalResult.isLearningMode());
        assertEquals(4, finalResult.getStageAfter());
        // Stage 4 interval (7) - Stage 3 interval (4) = 3 days
        assertEquals(DateUtils.calculateToday(refreshTime).plusDays(3), finalResult.getNextReviewDate());
        assertEquals(0, card.getConsecutiveFamiliar());
    }

    @Test
    void vagueOnStageTwoReturnsToStageTwoWithOneDayInterval() {
        Card card = new Card();
        card.setStage(2);

        SchedulingEngine.RatingResult vagueResult = engine.rateVague(card, refreshTime);

        assertEquals(1, vagueResult.getStageAfter());
        assertEquals(2, card.getReentryStage());
        assertTrue(vagueResult.isLearningMode());

        SchedulingEngine.RatingResult complete = engine.rateFamiliar(card, refreshTime);
        engine.rateFamiliar(card, refreshTime);
        SchedulingEngine.RatingResult finalResult = engine.rateFamiliar(card, refreshTime);

        assertFalse(finalResult.isLearningMode());
        assertEquals(2, finalResult.getStageAfter());
        assertEquals(DateUtils.calculateToday(refreshTime).plusDays(1), finalResult.getNextReviewDate());
        assertTrue(complete.isLearningMode());
    }

    @Test
    void forgetRelearningRequiresFiveFamiliarRatingsThenEntersStageOne() {
        Card card = new Card();
        card.setStage(6);
        engine.rateForget(card, refreshTime);

        for (int i = 0; i < 4; i++) {
            SchedulingEngine.RatingResult result = engine.rateFamiliar(card, refreshTime);
            assertTrue(result.isLearningMode(), "still relearning before fifth familiar");
            assertEquals(i + 1, result.getConsecutiveFamiliar());
        }

        SchedulingEngine.RatingResult finalResult = engine.rateFamiliar(card, refreshTime);
        assertFalse(finalResult.isLearningMode());
        assertEquals(1, finalResult.getStageAfter());
        assertEquals(DateUtils.calculateToday(refreshTime).plusDays(1), finalResult.getNextReviewDate());
    }

    @Test
    void nonFamiliarRatingDuringRelearningResetsCounterWithoutDowngrading() {
        Card card = new Card();
        card.setStage(5);
        engine.rateVague(card, refreshTime);
        engine.rateFamiliar(card, refreshTime);

        SchedulingEngine.RatingResult resetResult = engine.rateForget(card, refreshTime);
        assertEquals(0, resetResult.getConsecutiveFamiliar());
        assertEquals(0, card.getConsecutiveFamiliar());
        assertEquals(0, card.getStage());
    }

    @Test
    void vagueOnStageOneBehavesLikeForget() {
        Card card = new Card();
        card.setStage(1);

        SchedulingEngine.RatingResult result = engine.rateVague(card, refreshTime);

        assertEquals(0, result.getStageAfter());
        assertTrue(result.isLearningMode());
        assertNull(card.getReentryStage());
    }

    @Test
    void vagueOnStageZeroBehavesLikeForget() {
        Card card = new Card();
        card.setStage(0);

        SchedulingEngine.RatingResult result = engine.rateVague(card, refreshTime);

        assertEquals(0, result.getStageBefore());
        assertEquals(0, result.getStageAfter());
        assertTrue(result.isLearningMode());
        assertNull(card.getReentryStage());
    }

    @Test
    void vagueIntervalHelpersHandleBoundaryStages() {
        Card stageOne = new Card();
        stageOne.setStage(1);
        assertEquals(0, SchedulingEngine.getVagueIntervalAfterRating(stageOne));

        Card stageTwo = new Card();
        stageTwo.setStage(2);
        assertEquals(2, SchedulingEngine.getVagueIntervalAfterRating(stageTwo));
        assertEquals(1, SchedulingEngine.calculateVagueReviewInterval(2));
    }

    @Test
    void stageIntervalReturnsMaxForOutOfRangeStage() {
        assertEquals(180, SchedulingEngine.getStageInterval(-1));
        assertEquals(180, SchedulingEngine.getStageInterval(99));
    }
}
