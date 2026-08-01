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
     * Process a VAGUE rating.
     * Card goes back one stage, enters relearning mode with 2^n spacing.
     * Special case: Stage 1 VAGUE is treated as FORGET.
     */
    public RatingResult rateVague(Card card, LocalTime refreshTime) {
        int currentStage = card.getStage();

        // Stage 1 VAGUE = FORGET (no lower stage to go back to)
        if (currentStage <= 1) {
            return rateForget(card, refreshTime);
        }

        RatingResult result = new RatingResult();
        result.stageBefore = currentStage;

        int previousStage = currentStage - 1;
        card.setStage(previousStage);
        card.setLearningMode(true);
        card.setConsecutiveFamiliar(0);
        card.setLearningStep(0);
        // Set reentry stage to current stage (the one we'll return to after relearning)
        card.setReentryStage(currentStage);
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
    private int calculateVagueReviewInterval(int targetStage) {
        if (targetStage <= 1) return 1;
        return STAGE_INTERVALS[targetStage] - STAGE_INTERVALS[targetStage - 1];
    }

    /**
     * Determine the consecutive Familiar threshold for exiting relearning.
     * FORGET path: 5, VAGUE path: 3
     */
    private int getRelearningThreshold(Card card) {
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