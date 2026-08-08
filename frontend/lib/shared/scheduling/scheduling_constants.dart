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

  /// 逾期绝对宽限天数（架构评审 A2，2026-08-08）：逾期不超过该天数不触发
  /// 等效 stage 惩罚。与后端 SchedulingEngine.OVERDUE_GRACE_DAYS 一致，
  /// 已入单一数据源——禁止在引擎/UI 内硬编码字面量。
  static const int overdueGraceDays = 2;

  /// 默认每日刷新点（架构评审 C3，2026-08-08）：未配置用户/未同步时的兜底值。
  /// 此前在 sync/offline/settings/review/app_database 散落 13 处字面量，
  /// 现为单一数据源；与后端 UserRefreshTime.DEFAULT_REFRESH_TIME（04:00）一致。
  /// 注意：Drift 的 withDefault 需要 const 表达式，直接引用本常量。
  static const String defaultRefreshTime = '04:00:00';

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

  /// Vague 评分后的间隔预览（天，架构评审 A2，2026-08-08）：
  /// Stage 0/1 视同 FORGET（0 天），否则取等效 stage 的间隔（逾期时先按
  /// [LocalSchedulingEngine.calculateEffectiveStage] 折算，与后端
  /// SchedulingEngine.getVagueIntervalAfterRating(card, overdueDays) 对齐）。
  /// overdueDays 缺省 0 表示未逾期（保持原行为）；逾期卡传入实际逾期天数后，
  /// 预览与评分后的实际回归间隔一致。
  static int vagueIntervalAfterRating(int stage, {int overdueDays = 0}) {
    if (stage <= 1) return 0;
    if (overdueDays <= 0 || overdueDays <= overdueGraceDays) {
      return stageIntervals[stage];
    }
    // 与 LocalSchedulingEngine.calculateEffectiveStage 同一公式（宽限已在上方短路，
    // 这里只需按 log2(ρ) 折算；stage≤1 已返回，故结果恒 ≥1）。
    final interval = stageIntervals[stage];
    final elapsed = interval + overdueDays;
    var k = 0;
    var threshold = interval * 2;
    while (elapsed >= threshold) {
      k++;
      if (threshold > (1 << 62)) break;
      threshold *= 2;
    }
    final effective = stage - k < 1 ? 1 : stage - k;
    return stageIntervals[effective];
  }

  /// 重学插位偏移：第 1 次隔 1 张、第 2 次隔 2 张、第 3 次隔 4 张（2^n）。
  /// 与服务端 ReviewService.interleaveLearningCards 一致。
  static int relearningInsertOffset(int learningStep) => 1 << learningStep;
}
