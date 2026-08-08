import 'package:flutter_test/flutter_test.dart';
import 'package:karisreview/shared/scheduling/queue_composer.dart';

/// QueueComposer 插位规则单测（架构评审 F1）：
/// offset = 2^learningStep，clamp 到可用长度；baseOffset 支持会话内基准。
void main() {
  group('QueueComposer.interleave', () {
    test('learning_step 0 插到 offset=1（隔 1 张）', () {
      final result = QueueComposer.interleave(
        queue: [1, 2, 3],
        learningCards: [10],
        learningStepOf: (_) => 0,
      );
      expect(result, [1, 10, 2, 3]);
    });

    test('learning_step 1 插到 offset=2（隔 2 张）', () {
      final result = QueueComposer.interleave(
        queue: [1, 2, 3],
        learningCards: [10],
        learningStepOf: (_) => 1,
      );
      expect(result, [1, 2, 10, 3]);
    });

    test('learning_step 2 插到 offset=4（隔 4 张，超出长度则到末尾）', () {
      final result = QueueComposer.interleave(
        queue: [1, 2, 3],
        learningCards: [10],
        learningStepOf: (_) => 2,
      );
      expect(result, [1, 2, 3, 10]);
    });

    test('多张学习卡按给定顺序依次插入（基于更新后的队列定位）', () {
      final result = QueueComposer.interleave(
        queue: [1, 2, 3, 4, 5, 6, 7, 8],
        learningCards: [100, 200], // step 0 → offset 1；step 1 → offset 2
        learningStepOf: (card) => card == 100 ? 0 : 1,
      );
      // 100 插入 index 1；200 基于更新后队列插到 index 2。
      expect(result, [1, 100, 200, 2, 3, 4, 5, 6, 7, 8]);
    });

    test('baseOffset 以基准偏移定位（会话内插回不越过已消费位置）', () {
      // 已消费 3 张（currentIndex=3），step 1 → offset 2 → 插入到 index 5。
      final result = QueueComposer.interleave(
        queue: [1, 2, 3, 4, 5, 6],
        learningCards: [10],
        learningStepOf: (_) => 1,
        baseOffset: 3,
      );
      expect(result, [1, 2, 3, 4, 5, 10, 6]);
    });

    test('baseOffset 下 offset 超出剩余长度时插到队尾', () {
      // 已消费 4 张，剩余 2 张；step 2 → offset 4 clamp 到 2 → 队尾。
      final result = QueueComposer.interleave(
        queue: [1, 2, 3, 4, 5, 6],
        learningCards: [10],
        learningStepOf: (_) => 2,
        baseOffset: 4,
      );
      expect(result, [1, 2, 3, 4, 5, 6, 10]);
    });

    test('不修改入参队列', () {
      final original = [1, 2, 3];
      QueueComposer.interleave(
        queue: original,
        learningCards: [10],
        learningStepOf: (_) => 0,
      );
      expect(original, [1, 2, 3]);
    });

    test('无学习卡时原样返回', () {
      final result = QueueComposer.interleave(
        queue: [1, 2, 3],
        learningCards: <int>[],
        learningStepOf: (_) => 0,
      );
      expect(result, [1, 2, 3]);
    });
  });
}
