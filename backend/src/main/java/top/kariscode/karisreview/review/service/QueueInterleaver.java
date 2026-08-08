package top.kariscode.karisreview.review.service;

import top.kariscode.karisreview.card.entity.Card;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/**
 * 重学卡 2^n 插位纯算法（架构评审 B1，2026-08）。
 *
 * 此前 interleaveLearningCards 是 ReviewService 的私有方法，只能经
 * getDueCards 间接测试（需同时 stub 三个依赖）；抽为零依赖静态模块后
 * 可独立单测（接口即测试面），与前端 QueueComposer 为跨语言对应实现。
 *
 * 语义：学习卡按 (learningStep, createdAt) 排序后依次插入，每张的偏移
 * offset = 2^learningStep（第 1 次隔 1 张、第 2 次隔 2 张……），
 * 超出队列长度时插到队尾；定位基于更新后的队列（与历史实现一致）。
 */
public final class QueueInterleaver {

    private QueueInterleaver() {
    }

    public static List<Card> interleave(List<Card> base, List<Card> learningCards) {
        List<Card> queue = new ArrayList<>(base);
        if (learningCards.isEmpty()) {
            return queue;
        }
        List<Card> sortedLearning = learningCards.stream()
                .sorted(Comparator.comparingInt(Card::getLearningStep)
                        .thenComparing(Card::getCreatedAt))
                .toList();
        for (Card card : sortedLearning) {
            int offset = 1 << card.getLearningStep();
            int position = Math.min(offset, queue.size());
            queue.add(position, card);
        }
        return queue;
    }
}
