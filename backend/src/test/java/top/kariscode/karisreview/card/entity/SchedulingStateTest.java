package top.kariscode.karisreview.card.entity;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class SchedulingStateTest {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void writeToJsonRoundTripsAllFields() throws Exception {
        SchedulingState state = new SchedulingState(
                3, 2, LocalDate.of(2026, 8, 9), true,
                1, 2, "NEW");

        ObjectNode node = objectMapper.createObjectNode();
        state.writeTo(node);
        String json = objectMapper.writeValueAsString(node);

        // 排期状态 7 字段全量导出（含曾漏的 learning_step/learning_origin）
        assertEquals(3, node.get("stage").asInt());
        assertEquals(2, node.get("consecutive_familiar").asInt());
        assertEquals("2026-08-09", node.get("next_review_date").asText());
        assertEquals(true, node.get("learning_mode").asBoolean());
        assertEquals(1, node.get("reentry_stage").asInt());
        assertEquals(2, node.get("learning_step").asInt());
        assertEquals("NEW", node.get("learning_origin").asText());

        SchedulingState restored = SchedulingState.fromJson(
                objectMapper.readTree(json));
        assertEquals(state, restored);
    }

    @Test
    void fromJsonMissesKeysFallBackToDefaults() throws Exception {
        SchedulingState state = SchedulingState.fromJson(
                objectMapper.readTree("{\"front\":\"x\"}"));

        assertEquals(0, state.getStage());
        assertEquals(0, state.getConsecutiveFamiliar());
        assertNull(state.getNextReviewDate());
        assertEquals(false, state.isLearningMode());
        assertNull(state.getReentryStage());
        assertEquals(0, state.getLearningStep());
        assertNull(state.getLearningOrigin());
    }

    @Test
    void fromCardAndApplySchedulingStateKeepFieldsConsistent() {
        Card card = new Card();
        card.setStage(5);
        card.setConsecutiveFamiliar(4);
        card.setNextReviewDate(LocalDate.of(2026, 9, 1));
        card.setLearningMode(true);
        card.setReentryStage(3);
        card.setLearningStep(1);
        card.setLearningOrigin("REVIEW");

        SchedulingState state = card.getSchedulingState();
        assertEquals(new SchedulingState(5, 4, LocalDate.of(2026, 9, 1), true,
                3, 1, "REVIEW"), state);

        Card target = new Card();
        target.applySchedulingState(state);
        assertEquals(card.getSchedulingState(), target.getSchedulingState());
    }
}
