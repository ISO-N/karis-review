import 'scheduling_constants.dart';

/// 重学卡插位单一实现（架构评审 F1，2026-08）。
///
/// 学新/复习队列的 2^n 重学插位此前在 OfflineRepository.getDueQueue、
/// getNewQueue 与会话内 _reinsertRelearningCard 各写一遍，一致性靠注释声称。
/// 本类收敛插位语义：offset = 2^learningStep（[SchedulingConstants]），
/// 以 baseOffset 为基准插入。调用方负责学习卡排序与基准选择——
/// 离线重建 baseOffset=0，会话内实时插回 baseOffset=已消费的 currentIndex。
class QueueComposer {
  QueueComposer._();

  /// 将 [learningCards] 按 2^n 间距插入 [queue] 并返回新队列（不修改入参）。
  ///
  /// 每张卡的位置 = baseOffset + min(2^learningStep, 当前可用长度)，
  /// 可用长度随插入动态增长（与历史实现一致：每次基于更新后的队列定位）；
  /// 插入顺序即 [learningCards] 顺序，调用方应先按 (learningStep, createdAt)
  /// 排序（离线重建）。
  static List<T> interleave<T>({
    required List<T> queue,
    required List<T> learningCards,
    required int Function(T) learningStepOf,
    int baseOffset = 0,
  }) {
    final result = List<T>.from(queue);
    for (final card in learningCards) {
      final available = result.length - baseOffset;
      final offset = SchedulingConstants.relearningInsertOffset(
        learningStepOf(card),
      ).clamp(0, available);
      result.insert(baseOffset + offset, card);
    }
    return result;
  }
}
