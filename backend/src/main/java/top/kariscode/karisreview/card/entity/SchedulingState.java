package top.kariscode.karisreview.card.entity;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

import java.time.LocalDate;
import java.util.Objects;

/**
 * 排期状态值对象（架构评审候选 2，2026-08）。
 *
 * 卡片排期状态的唯一载体：stage / consecutiveFamiliar / nextReviewDate /
 * learningMode / reentryStage / learningStep / learningOrigin。
 * 所有出口（CardResponse / ReviewCardResponse / BootstrapCard / 备份 JSON）
 * 都应从本对象投影，杜绝字段集合各说各话（备份曾漏 learning_step /
 * learning_origin / review_version 导致恢复后队列归属退化与插位丢失）。
 *
 * reviewVersion（乐观锁）不属于排期语义，不进入本对象，由备份层单独携带。
 */
public class SchedulingState {

    private final int stage;
    private final int consecutiveFamiliar;
    private final LocalDate nextReviewDate;
    private final boolean learningMode;
    private final Integer reentryStage;
    private final int learningStep;
    private final String learningOrigin;

    public SchedulingState(int stage, int consecutiveFamiliar,
                           LocalDate nextReviewDate, boolean learningMode,
                           Integer reentryStage, int learningStep,
                           String learningOrigin) {
        this.stage = stage;
        this.consecutiveFamiliar = consecutiveFamiliar;
        this.nextReviewDate = nextReviewDate;
        this.learningMode = learningMode;
        this.reentryStage = reentryStage;
        this.learningStep = learningStep;
        this.learningOrigin = learningOrigin;
    }

    public static SchedulingState from(Card card) {
        return new SchedulingState(
                card.getStage(), card.getConsecutiveFamiliar(),
                card.getNextReviewDate(), card.isLearningMode(),
                card.getReentryStage(), card.getLearningStep(),
                card.getLearningOrigin());
    }

    /** 写入备份 JSON 节点（snake_case 键，与既有导出格式一致）。 */
    public void writeTo(ObjectNode node) {
        node.put("stage", stage);
        node.put("consecutive_familiar", consecutiveFamiliar);
        node.put("next_review_date", nextReviewDate != null ? nextReviewDate.toString() : null);
        node.put("learning_mode", learningMode);
        node.put("reentry_stage", reentryStage);
        node.put("learning_step", learningStep);
        node.put("learning_origin", learningOrigin);
    }

    /** 从备份 JSON 节点恢复；缺键/空值回退默认（与 Card 实体默认一致，兼容旧备份）。 */
    public static SchedulingState fromJson(JsonNode node) {
        return new SchedulingState(
                node.has("stage") ? node.get("stage").asInt() : 0,
                node.has("consecutive_familiar") ? node.get("consecutive_familiar").asInt() : 0,
                node.has("next_review_date") && !node.get("next_review_date").isNull()
                        ? LocalDate.parse(node.get("next_review_date").asText()) : null,
                node.has("learning_mode") && node.get("learning_mode").asBoolean(),
                node.has("reentry_stage") && !node.get("reentry_stage").isNull()
                        ? node.get("reentry_stage").asInt() : null,
                node.has("learning_step") ? node.get("learning_step").asInt() : 0,
                node.has("learning_origin") && !node.get("learning_origin").isNull()
                        ? node.get("learning_origin").asText() : null);
    }

    public int getStage() { return stage; }
    public int getConsecutiveFamiliar() { return consecutiveFamiliar; }
    public LocalDate getNextReviewDate() { return nextReviewDate; }
    public boolean isLearningMode() { return learningMode; }
    public Integer getReentryStage() { return reentryStage; }
    public int getLearningStep() { return learningStep; }
    public String getLearningOrigin() { return learningOrigin; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof SchedulingState that)) return false;
        return stage == that.stage
                && consecutiveFamiliar == that.consecutiveFamiliar
                && learningMode == that.learningMode
                && learningStep == that.learningStep
                && Objects.equals(nextReviewDate, that.nextReviewDate)
                && Objects.equals(reentryStage, that.reentryStage)
                && Objects.equals(learningOrigin, that.learningOrigin);
    }

    @Override
    public int hashCode() {
        return Objects.hash(stage, consecutiveFamiliar, nextReviewDate,
                learningMode, reentryStage, learningStep, learningOrigin);
    }

    @Override
    public String toString() {
        return "SchedulingState{stage=" + stage
                + ", consecutiveFamiliar=" + consecutiveFamiliar
                + ", nextReviewDate=" + nextReviewDate
                + ", learningMode=" + learningMode
                + ", reentryStage=" + reentryStage
                + ", learningStep=" + learningStep
                + ", learningOrigin=" + learningOrigin + '}';
    }
}
