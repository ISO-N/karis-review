package top.kariscode.karisreview.review.service;

import org.springframework.stereotype.Component;
import top.kariscode.karisreview.card.entity.Card;
import top.kariscode.karisreview.common.util.DateUtils;

import java.time.LocalDate;
import java.time.LocalTime;

/**
 * Core scheduling algorithm for spaced repetition.
 * Implements the card stage progression and review scheduling logic.
 *
 * Stage intervals:
 *  Stage 0: Learning (new cards)
 *  Stage 1: 1 day
 *  Stage 2: 2 days
 *  Stage 3: 4 days
 *  Stage 4: 7 days
 *  Stage 5: 15 days
 *  Stage 6: 30 days
 *  Stage 7: 90 days
 *  Stage 8: 180 days
 */
@Component
public class SchedulingEngine {

    private static final int[] STAGE_INTERVALS = {0, 1, 2, 4, 7, 15, 30, 90, 180};
    private static final int MAX_STAGE = 8;
    private static final int FORGET_CONSECUTIVE_FAMILIAR_THRESHOLD = 5;
    private static final int VAGUE_CONSECUTIVE_FAMILIAR_THRESHOLD = 3;
    /** 绝对宽限天数：逾期不超过该天数不触发惩罚。 */
    private static final int OVERDUE_GRACE_DAYS = 2;

    /**
     * Process a FAMILIAR rating.
     * Card advances to the next stage, next review date is calculated.
     * If in learning mode, increments consecutive familiar counter.
     */
    public RatingResult rateFamiliar(Card card, LocalTime refreshTime) {
        int originalStage = card.getStage();
        RatingResult result = new RatingResult();
        result.stageBefore = originalStage;

        if (card.isLearningMode()) {
            // In relearning mode - increment consecutive familiar
            int newCount = card.getConsecutiveFamiliar() + 1;
            result.consecutiveFamiliar = newCount;
            card.setConsecutiveFamiliar(newCount);

            // Determine threshold based on whether this was FORGET or VAGUE
            int threshold = getRelearningThreshold(card);

            if (newCount >= threshold) {
                // Exit relearning mode
                card.setLearningMode(false);
                card.setConsecutiveFamiliar(0);
                card.setLearningStep(0);

                // Determine the stage to go to
                if (card.getReentryStage() != null && card.getReentryStage() > 0) {
                    // VAGUE path: go to reentry stage
                    int targetStage = card.getReentryStage();
                    card.setReentryStage(null);
                    card.setStage(targetStage);

                    // Calculate next review date: current stage interval - previous stage interval
                    int interval = calculateVagueReviewInterval(targetStage);
                    card.setNextReviewDate(DateUtils.calculateToday(refreshTime).plusDays(interval));
                    result.stageAfter = targetStage;
                } else {
                    // FORGET path: go to Stage 1
                    card.setStage(1);
                    card.setNextReviewDate(DateUtils.calculateToday(refreshTime).plusDays(1));
                    result.stageAfter = 1;
                }
                result.learningMode = false;
            } else {
                // Still in relearning - increment step for 2^n spacing
                card.setLearningStep(card.getLearningStep() + 1);
                card.setNextReviewDate(DateUtils.calculateToday(refreshTime));
                result.stageAfter = originalStage;
                result.learningMode = true;
            }
        } else {
            // Normal FAMILIAR - advance to next stage
            if (originalStage == 0) {
                // Learning stage -> Stage 1
                card.setStage(1);
                card.setNextReviewDate(DateUtils.calculateToday(refreshTime).plusDays(1));
                result.stageAfter = 1;
            } else if (originalStage < MAX_STAGE) {
                int newStage = originalStage + 1;
                card.setStage(newStage);
                card.setNextReviewDate(DateUtils.calculateToday(refreshTime).plusDays(STAGE_INTERVALS[newStage]));
                result.stageAfter = newStage;
            } else {
                // Already at max stage (Stage 8, 180 days)
                card.setNextReviewDate(DateUtils.calculateToday(refreshTime).plusDays(STAGE_INTERVALS[MAX_STAGE]));
                result.stageAfter = MAX_STAGE;
            }
            result.learningMode = false;
            result.consecutiveFamiliar = 0;
        }

        result.nextReviewDate = card.getNextReviewDate();
        return result;
    }

    /**
     * Process a FORGET rating.
     * Card resets to Stage 0, enters relearning mode with 2^n spacing.
     */
    public RatingResult rateForget(Card card, LocalTime refreshTime) {
        int originalStage = card.getStage();
        RatingResult result = new RatingResult();
        result.stageBefore = originalStage;

        card.setStage(0);
        card.setLearningMode(true);
        card.setConsecutiveFamiliar(0);
        card.setLearningStep(0);
        card.setReentryStage(null);
        card.setNextReviewDate(DateUtils.calculateToday(refreshTime));
        result.stageAfter = 0;
        result.learningMode = true;
        result.consecutiveFamiliar = 0;
        result.nextReviewDate = card.getNextReviewDate();

        return result;
    }

    /**
     * Calculate the effective stage for an overdue card, based on the Ebbinghaus
     * forgetting curve. Each stage's interval defines its own retention curve;
     * an overdue card's forgetting degree is estimated as equivalent to a lower
     * stage at the same relative position.
     *
     * For stage n with interval I and overdue days d, the overdue ratio is
     * ρ = (I + d) / I. The card forgets as if it were k = floor(log2(ρ)) stages
     * lower, so the effective stage is max(1, n − k). ρ < 2 means less than one
     * full interval overdue and incurs no penalty.
     *
     * Grace rules: no penalty when d ≤ OVERDUE_GRACE_DAYS (absolute grace for
     * short intervals) or when ρ < 2.
     * Example: stage 4 (7d) overdue 7 days → ρ = 2 → effective stage 3.
     */
    public static int calculateEffectiveStage(int stage, int overdueDays) {
        if (stage <= 1 || overdueDays <= 0) {
            return stage;
        }
        if (overdueDays <= OVERDUE_GRACE_DAYS) {
            return stage;
        }
        int interval = getStageInterval(stage);
        int elapsed = interval + overdueDays;
        // k = floor(log2(ρ))：k 从 0 递增，直到 elapsed < 2^(k+1) * interval
        int k = 0;
        long threshold = interval * 2L;
        while (elapsed >= threshold) {
            k++;
            if (threshold > Long.MAX_VALUE / 2) {
                break;
            }
            threshold *= 2;
        }
        return Math.max(1, stage - k);
    }

    /**
     * Process a VAGUE rating.
     * Card goes back one stage (from the effective stage when overdue),
     * enters relearning mode with 2^n spacing.
     * Special case: effective stage 1 VAGUE is treated as FORGET.
     */
    public RatingResult rateVague(Card card, LocalTime refreshTime) {
        return rateVague(card, refreshTime, 0);
    }

    /**
     * Process a VAGUE rating on a card that may be overdue.
     * The stage to step back from is the effective stage
     * (see {@link #calculateEffectiveStage}).
     */
    public RatingResult rateVague(Card card, LocalTime refreshTime, int overdueDays) {
        int currentStage = card.getStage();
        int effectiveStage = calculateEffectiveStage(currentStage, overdueDays);

        // Effective stage 1 VAGUE = FORGET (no lower stage to go back to)
        if (effectiveStage <= 1) {
            return rateForget(card, refreshTime);
        }

        RatingResult result = new RatingResult();
        result.stageBefore = currentStage;

        int previousStage = effectiveStage - 1;
        card.setStage(previousStage);
        card.setLearningMode(true);
        card.setConsecutiveFamiliar(0);
        card.setLearningStep(0);
        // Set reentry stage to the effective stage (the one we'll return to after relearning)
        card.setReentryStage(effectiveStage);
        card.setNextReviewDate(DateUtils.calculateToday(refreshTime));
        result.stageAfter = previousStage;
        result.learningMode = true;
        result.consecutiveFamiliar = 0;
        result.nextReviewDate = card.getNextReviewDate();

        return result;
    }

    /**
     * Calculate the review interval after VAGUE relearning completes.
     * Formula: current stage interval - previous stage interval
     * Example: Stage 4 (7 days) - Stage 3 (4 days) = 3 days
     */
    public static int calculateVagueReviewInterval(int targetStage) {
        if (targetStage <= 1) return 1;
        return STAGE_INTERVALS[targetStage] - STAGE_INTERVALS[targetStage - 1];
    }

    /**
     * Determine the consecutive Familiar threshold for exiting relearning.
     * FORGET path: 5, VAGUE path: 3
     */
    public static int getRelearningThreshold(Card card) {
        return card.getReentryStage() != null && card.getReentryStage() > 0
                ? VAGUE_CONSECUTIVE_FAMILIAR_THRESHOLD
                : FORGET_CONSECUTIVE_FAMILIAR_THRESHOLD;
    }

    /**
     * Get the interval for a given stage.
     */
    public static int getStageInterval(int stage) {
        if (stage < 0 || stage > MAX_STAGE) return STAGE_INTERVALS[MAX_STAGE];
        return STAGE_INTERVALS[stage];
    }

    public static int getFamiliarIntervalAfterRating(Card card) {
        if (card.isLearningMode()) {
            int threshold = getRelearningThreshold(card);
            if (card.getConsecutiveFamiliar() + 1 >= threshold) {
                Integer targetStage = card.getReentryStage();
                if (targetStage != null && targetStage > 0) {
                    return calculateVagueReviewInterval(targetStage);
                }
                return STAGE_INTERVALS[1];
            }
            return 0;
        }
        if (card.getStage() >= MAX_STAGE) return STAGE_INTERVALS[MAX_STAGE];
        return STAGE_INTERVALS[card.getStage() + 1];
    }

    public static int getVagueIntervalAfterRating(Card card) {
        return getVagueIntervalAfterRating(card, 0);
    }

    /**
     * Interval preview for a VAGUE rating, taking overdue days into account:
     * the step-back happens from the effective stage, so the preview shows the
     * reentry interval the card would receive after relearning.
     */
    public static int getVagueIntervalAfterRating(Card card, int overdueDays) {
        int effectiveStage = calculateEffectiveStage(card.getStage(), overdueDays);
        if (effectiveStage <= 1) return 0;
        return STAGE_INTERVALS[effectiveStage];
    }

    /**
     * Result of a rating operation.
     */
    public static class RatingResult {
        private int stageBefore;
        private int stageAfter;
        private boolean learningMode;
        private int consecutiveFamiliar;
        private LocalDate nextReviewDate;

        public int getStageBefore() { return stageBefore; }
        public void setStageBefore(int stageBefore) { this.stageBefore = stageBefore; }
        public int getStageAfter() { return stageAfter; }
        public void setStageAfter(int stageAfter) { this.stageAfter = stageAfter; }
        public boolean isLearningMode() { return learningMode; }
        public void setLearningMode(boolean learningMode) { this.learningMode = learningMode; }
        public int getConsecutiveFamiliar() { return consecutiveFamiliar; }
        public void setConsecutiveFamiliar(int consecutiveFamiliar) { this.consecutiveFamiliar = consecutiveFamiliar; }
        public LocalDate getNextReviewDate() { return nextReviewDate; }
        public void setNextReviewDate(LocalDate nextReviewDate) { this.nextReviewDate = nextReviewDate; }
    }
}