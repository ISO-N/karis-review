package top.kariscode.karisreview.review.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import top.kariscode.karisreview.card.entity.Card;
import top.kariscode.karisreview.common.util.DateUtils;

import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;
import java.time.LocalTime;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;

/**
 * 排期公式跨语言等价性测试（架构评审 A1，2026-08-08）。
 *
 * <p>读取 docs/design/scheduling-vectors.json（语言无关单一事实源），对每条向量
 * 调用 SchedulingEngine 断言结果。前端 local_scheduling_engine 的向量测试读同一份
 * 文件——改公式必须改向量文件且两端测试同绿。</p>
 *
 * <p>向量文件相对路径：测试工作目录为 backend/，文件位于仓库根的 docs/design/。</p>
 */
class SchedulingVectorsTest {

    private final SchedulingEngine engine = new SchedulingEngine();
    private final LocalTime refreshTime = LocalTime.of(4, 0);
    private final ObjectMapper mapper = new ObjectMapper();

    private JsonNode loadVectors() {
        try {
            Path vectorPath = Path.of("../docs/design/scheduling-vectors.json");
            if (!Files.exists(vectorPath)) {
                // 兜底：从仓库根直接找
                vectorPath = Path.of("../karis-review/docs/design/scheduling-vectors.json");
            }
            if (!Files.exists(vectorPath)) {
                fail("找不到 scheduling-vectors.json，请确认文件位于 docs/design/ 下");
            }
            return mapper.readTree(Files.readAllBytes(vectorPath));
        } catch (Exception e) {
            throw new RuntimeException("读取 scheduling-vectors.json 失败", e);
        }
    }

    @Test
    void allRatingVectorsMatchBackendEngine() throws Exception {
        JsonNode root = loadVectors();
        int ratingCases = 0;
        int effectiveCases = 0;
        for (JsonNode v : root.get("vectors")) {
            String id = v.get("id").asText();
            JsonNode input = v.get("input");
            JsonNode expected = v.get("expected");
            String rating = input.get("rating").asText();

            if ("NONE".equals(rating)) {
                // effectiveStage 纯函数向量
                int stage = input.get("stage").asInt();
                int overdueDays = input.get("overdueDays").asInt();
                int actual = SchedulingEngine.calculateEffectiveStage(stage, overdueDays);
                int want = expected.get("effectiveStage").asInt();
                assertEquals(want, actual, "effectiveStage 向量 " + id);
                effectiveCases++;
                continue;
            }

            Card card = new Card();
            card.setStage(input.get("stage").asInt());
            card.setLearningMode(input.get("learningMode").asBoolean());
            card.setConsecutiveFamiliar(input.get("consecutiveFamiliar").asInt());
            card.setLearningStep(input.get("learningStep").asInt());
            JsonNode reentry = input.get("reentryStage");
            if (!reentry.isNull()) {
                card.setReentryStage(reentry.asInt());
            }
            JsonNode originInput = input.get("learningOriginInput");
            if (originInput != null && !originInput.isNull()) {
                card.setLearningOrigin(originInput.asText());
            }

            int overdueDays = input.get("overdueDays").asInt();
            SchedulingEngine.RatingResult result = switch (rating) {
                case "FAMILIAR" -> engine.rateFamiliar(card, refreshTime);
                case "FORGET" -> engine.rateForget(card, refreshTime);
                case "VAGUE" -> engine.rateVague(card, refreshTime, overdueDays);
                default -> throw new IllegalArgumentException("未知 rating: " + rating);
            };

            LocalDate today = DateUtils.calculateToday(refreshTime);
            long intervalDays = result.getNextReviewDate().toEpochDay() - today.toEpochDay();

            assertEquals(expected.get("stageAfter").asInt(), result.getStageAfter(), "向量 " + id + " stageAfter");
            assertEquals(expected.get("learningMode").asBoolean(), result.isLearningMode(), "向量 " + id + " learningMode");
            // 卡片最终状态（脱离重学后 consecutive_familiar 重置为 0；RatingResult 记录的是进入判断的计数，语义与卡片不同）
            assertEquals(expected.get("consecutiveFamiliar").asInt(), card.getConsecutiveFamiliar(), "向量 " + id + " consecutiveFamiliar");
            assertEquals(expected.get("nextIntervalDays").asInt(), intervalDays, "向量 " + id + " nextIntervalDays");

            String wantOrigin = expected.has("learningOrigin") && !expected.get("learningOrigin").isNull()
                    ? expected.get("learningOrigin").asText() : null;
            String actualOrigin = card.getLearningOrigin();
            if (wantOrigin == null) {
                assertNull(actualOrigin, "向量 " + id + " learningOrigin 应为 null");
            } else {
                assertEquals(wantOrigin, actualOrigin, "向量 " + id + " learningOrigin");
            }

            JsonNode wantReentry = expected.has("reentryStageAfter") ? expected.get("reentryStageAfter") : null;
            if (wantReentry != null && !wantReentry.isNull()) {
                assertTrue(card.getReentryStage() != null && card.getReentryStage() == wantReentry.asInt(),
                        "向量 " + id + " reentryStage");
            } else if (wantReentry != null) {
                assertNull(card.getReentryStage(), "向量 " + id + " reentryStage 应为 null");
            }
            ratingCases++;
        }
        assertTrue(ratingCases >= 15, "评分向量用例数不足: " + ratingCases);
        assertTrue(effectiveCases >= 8, "effectiveStage 向量用例数不足: " + effectiveCases);
    }
}
