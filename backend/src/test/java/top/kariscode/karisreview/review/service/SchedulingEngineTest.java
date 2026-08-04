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

    @Test
    void effectiveStageMapsOverdueRatioToLowerStage() {
        // ρ = 1：无逾期，stage 不变
        assertEquals(4, SchedulingEngine.calculateEffectiveStage(4, 0));
        // ρ < 2：宽限内（逾期 3 天 < 间隔 7），stage 不变
        assertEquals(4, SchedulingEngine.calculateEffectiveStage(4, 3));
        // ρ = 2：stage 4 (7d) 逾期 7 天 → 等效 stage 3
        assertEquals(3, SchedulingEngine.calculateEffectiveStage(4, 7));
        // ρ ≈ 3.86：stage 4 逾期 20 天 → k=1 → 等效 stage 3
        assertEquals(3, SchedulingEngine.calculateEffectiveStage(4, 20));
        // ρ ≈ 12.7：stage 4 逾期 82 天 → k=3 → 等效 stage 1
        assertEquals(1, SchedulingEngine.calculateEffectiveStage(4, 82));
        // 高 stage：stage 8 (180d) 逾期 60 天 → ρ ≈ 1.33 → 等效 stage 8
        assertEquals(8, SchedulingEngine.calculateEffectiveStage(8, 60));
        // 高 stage：stage 8 逾期 200 天 → ρ ≈ 2.1 → 等效 stage 7
        assertEquals(7, SchedulingEngine.calculateEffectiveStage(8, 200));
        // 极重逾期：stage 8 逾期 5 年 → 最低降到 stage 1，且降级数不超过 log2(ρ)
        assertTrue(SchedulingEngine.calculateEffectiveStage(8, 1825) >= 3);
    }

    @Test
    void effectiveStageAppliesGraceRules() {
        // 绝对宽限：逾期 ≤ 2 天不罚
        assertEquals(4, SchedulingEngine.calculateEffectiveStage(4, 2));
        assertEquals(3, SchedulingEngine.calculateEffectiveStage(3, 2));
        // stage 1/0 不参与惩罚（无更低可退）
        assertEquals(1, SchedulingEngine.calculateEffectiveStage(1, 30));
        assertEquals(0, SchedulingEngine.calculateEffectiveStage(0, 30));
    }

    @Test
    void vagueOnOverdueCardStepsBackFromEffectiveStage() {
        // stage 4（7 天）逾期 7 天 → 等效 stage 3 → 降到 stage 2、reentry 3
        Card card = new Card();
        card.setStage(4);
        card.setNextReviewDate(DateUtils.calculateToday(refreshTime).minusDays(7));

        SchedulingEngine.RatingResult result = engine.rateVague(card, refreshTime, 7);

        assertEquals(2, result.getStageAfter());
        assertEquals(3, card.getReentryStage());
        assertTrue(result.isLearningMode());
    }

    @Test
    void vagueOverdueRelearningReturnsToEffectiveStage() {
        // stage 4 逾期 7 天 → 等效 3 → 重学完成后回到 stage 3
        Card card = new Card();
        card.setStage(4);
        engine.rateVague(card, refreshTime, 7);
        assertEquals(3, card.getReentryStage());

        engine.rateFamiliar(card, refreshTime);
        engine.rateFamiliar(card, refreshTime);
        SchedulingEngine.RatingResult finalResult = engine.rateFamiliar(card, refreshTime);

        assertFalse(finalResult.isLearningMode());
        assertEquals(3, finalResult.getStageAfter());
        // stage 3 间隔 (4) − stage 2 间隔 (2) = 2 天
        assertEquals(DateUtils.calculateToday(refreshTime).plusDays(2), finalResult.getNextReviewDate());
    }

    @Test
    void vagueOnOverdueStageOneBehavesLikeForget() {
        // stage 1 逾期再久也按 FORGET 处理
        Card card = new Card();
        card.setStage(1);

        SchedulingEngine.RatingResult result = engine.rateVague(card, refreshTime, 10);

        assertEquals(0, result.getStageAfter());
        assertTrue(result.isLearningMode());
        assertNull(card.getReentryStage());
    }

    @Test
    void vagueOnHeavilyOverdueCardDegradesToForget() {
        // stage 2（2 天）逾期 30 天 → 等效 stage 1 → 视同 FORGET
        Card card = new Card();
        card.setStage(2);

        SchedulingEngine.RatingResult result = engine.rateVague(card, refreshTime, 30);

        assertEquals(0, result.getStageAfter());
        assertTrue(result.isLearningMode());
        assertNull(card.getReentryStage());
    }

    @Test
    void vagueWithinGracePeriodDoesNotDowngradeExtra() {
        // stage 4 逾期 2 天：绝对宽限内，行为与未逾期一致
        Card card = new Card();
        card.setStage(4);

        SchedulingEngine.RatingResult result = engine.rateVague(card, refreshTime, 2);

        assertEquals(3, result.getStageAfter());
        assertEquals(4, card.getReentryStage());
    }

    @Test
    void vagueIntervalPreviewAccountsForOverdue() {
        Card card = new Card();
        card.setStage(4);
        assertEquals(7, SchedulingEngine.getVagueIntervalAfterRating(card));
        assertEquals(4, SchedulingEngine.getVagueIntervalAfterRating(card, 7));
        assertEquals(0, SchedulingEngine.getVagueIntervalAfterRating(card, 82));
    }
}
