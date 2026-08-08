/// 排期常量与公式单一数据源（架构评审候选 5，2026-08）。
///
/// 此前间隔表在 local_scheduling_engine.dart / review_card.dart /
/// app/theme.dart 三处副本，3/5 阈值与 familiar/vague 间隔公式双份实现，
/// 2^n 重学插位三处散落——改排程漏改即静默错排。
/// 本类收敛后：LocalSchedulingEngine 与 ReviewCard 委托本类公式，
/// UI（theme.dart）不再持有业务常量，插位偏移统一走 [relearningInsertOffset]。
///
/// 对应后端 review/service/SchedulingEngine.java（Java 独立一份，跨语言无法
/// 共享源码；前后端公式一致由 LocalSchedulingEngineTest 与系统测试保障，
/// 改公式必须两端同步——见 docs/design/architecture.md 排期算法章节）。
class SchedulingConstants {
  SchedulingConstants._();

  /// Stage 0-8 复习间隔（天）。与后端 SchedulingEngine.INTERVALS 一致。
  static const List<int> stageIntervals = [0, 1, 2, 4, 7, 15, 30, 90, 180];

  static const int maxStage = 8;

  /// FORGET 重学：连续 5 次 Familiar 脱离（回 Stage 1）。
  static const int forgetThreshold = 5;

  /// VAGUE 重学：连续 3 次 Familiar 脱离（回 reentryStage）。
  static const int vagueThreshold = 3;

  /// 间隔天数显示标签（记忆刻度/统计页用）。与 [stageIntervals] 一一对应。
  static const List<String> stageLabels = [
    '0', '1', '2', '4', '7', '15', '30', '90', '180',
  ];

  /// 越界保护取间隔。
  static int stageInterval(int stage) {
    if (stage < 0 || stage > maxStage) return stageIntervals[maxStage];
    return stageIntervals[stage];
  }

  /// 重学脱离阈值：VAGUE 重学（reentryStage > 0）3 次，否则 5 次。
  static int relearningThreshold(int? reentryStage) =>
      reentryStage != null && reentryStage > 0 ? vagueThreshold : forgetThreshold;

  /// VAGUE 重学的回归间隔：目标级间隔 − 上一级间隔。
  static int vagueIntervalForTarget(int targetStage) =>
      stageIntervals[targetStage] - stageIntervals[targetStage - 1];

  /// Familiar 评分后的间隔（天）。与后端 SchedulingEngine 公式一致：
  /// 学习模式达标后回 reentryStage（回归间隔）或 Stage 1；否则非学习模式升一级。
  static int familiarIntervalAfterRating({
    required int stage,
    required bool learningMode,
    required int consecutiveFamiliar,
    required int? reentryStage,
  }) {
    if (learningMode) {
      final threshold = relearningThreshold(reentryStage);
      if (consecutiveFamiliar + 1 >= threshold) {
        if (reentryStage != null && reentryStage > 0) {
          return vagueIntervalForTarget(reentryStage);
        }
        return stageIntervals[1];
      }
      return 0;
    }
    if (stage >= maxStage) return stageIntervals[maxStage];
    return stageIntervals[stage + 1];
  }

  /// Vague 评分后的间隔（天）：Stage 0/1 视同 FORGET（0 天），否则当前级间隔。
  static int vagueIntervalAfterRating(int stage) {
    if (stage <= 1) return 0;
    return stageIntervals[stage];
  }

  /// 重学插位偏移：第 1 次隔 1 张、第 2 次隔 2 张、第 3 次隔 4 张（2^n）。
  /// 与服务端 ReviewService.interleaveLearningCards 一致。
  static int relearningInsertOffset(int learningStep) => 1 << learningStep;
}
