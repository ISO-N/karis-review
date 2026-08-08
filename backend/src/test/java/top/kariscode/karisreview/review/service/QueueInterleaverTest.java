package top.kariscode.karisreview.review.service;

import org.junit.jupiter.api.Test;
import top.kariscode.karisreview.card.entity.Card;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertIterableEquals;

/**
 * QueueInterleaver 插位规则单测（架构评审 B1）：
 * 此前插位是 ReviewService 私有方法，只能经 getDueCards 间接测
 * （需同时 stub 三个依赖）；抽为零依赖模块后接口即测试面。
 */
class QueueInterleaverTest {

    private Card card(String front, int learningStep) {
        Card card = new Card();
        card.setId(UUID.randomUUID());
        card.setDeckId(UUID.randomUUID());
        card.setUserId(UUID.randomUUID());
        card.setFront(front);
        card.setLearningStep(learningStep);
        return card;
    }

    private List<String> fronts(List<Card> cards) {
        return cards.stream().map(Card::getFront).toList();
    }

    @Test
    void learningStepZeroInsertsAtOffsetOne() {
        List<Card> queue = QueueInterleaver.interleave(
                List.of(card("A", 0), card("B", 0), card("C", 0)),
                List.of(card("L", 0)));

        assertEquals(List.of("A", "L", "B", "C"), fronts(queue));
    }

    @Test
    void learningStepOneInsertsAtOffsetTwo() {
        List<Card> queue = QueueInterleaver.interleave(
                List.of(card("A", 0), card("B", 0), card("C", 0)),
                List.of(card("L", 1)));

        assertEquals(List.of("A", "B", "L", "C"), fronts(queue));
    }

    @Test
    void offsetBeyondQueueLengthInsertsAtTail() {
        List<Card> queue = QueueInterleaver.interleave(
                List.of(card("A", 0), card("B", 0), card("C", 0)),
                List.of(card("L", 2)));

        assertEquals(List.of("A", "B", "C", "L"), fronts(queue));
    }

    @Test
    void multipleLearningCardsInsertedInLearningStepOrder() {
        // 传入乱序：step 1 在前、step 0 在后，应先按 learningStep 排序再插入。
        List<Card> queue = QueueInterleaver.interleave(
                List.of(card("A", 0), card("B", 0), card("C", 0),
                        card("D", 0), card("E", 0), card("F", 0)),
                List.of(card("L2", 1), card("L1", 0)));

        // L1(step0) → offset 1；L2(step1) 基于更新后队列 → offset 2。
        assertEquals(List.of("A", "L1", "L2", "B", "C", "D", "E", "F"), fronts(queue));
    }

    @Test
    void emptyLearningCardsReturnsBaseQueueUnchanged() {
        List<Card> base = List.of(card("A", 0), card("B", 0));
        List<Card> queue = QueueInterleaver.interleave(base, List.of());

        assertIterableEquals(base, queue);
    }
}
