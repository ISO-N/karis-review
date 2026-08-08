import '../card/models/card.dart';
import '../review/models/review_card.dart';
import '../shared/scheduling/scheduling_constants.dart';
import '../shared/utils/app_timezone.dart';

class LocalRatingOutcome {
  final FlashCard card;
  final ReviewResult result;
  final bool wasNewCard;
  final int reviewVersionBefore;

  const LocalRatingOutcome({
    required this.card,
    required this.result,
    required this.wasNewCard,
    required this.reviewVersionBefore,
  });
}

class LocalSchedulingEngine {
  // 常量与公式单一数据源（架构评审候选 5）：见 shared/scheduling/scheduling_constants.dart。
  static const List<int> stageIntervals = SchedulingConstants.stageIntervals;
  static const int maxStage = SchedulingConstants.maxStage;
  static const int forgetThreshold = SchedulingConstants.forgetThreshold;
  static const int vagueThreshold = SchedulingConstants.vagueThreshold;

  LocalRatingOutcome rate(
    FlashCard card,
    String rating, {
    DateTime? nowUtc,
    String refreshTime = '04:00:00',
  }) {
    final now = (nowUtc ?? DateTime.now().toUtc());
    final today = _calculateToday(now, refreshTime);
    final before = card.stage;
    final wasNewCard = card.stage == 0 && !card.learningMode;
    final reviewVersionBefore = card.reviewVersion;
    final overdueDays = card.nextReviewDate == null
        ? 0
        : (today.difference(DateTime.parse(card.nextReviewDate!)).inDays < 0
            ? 0
            : today.difference(DateTime.parse(card.nextReviewDate!)).inDays);
    var stage = card.stage;
    var learningMode = card.learningMode;
    var consecutiveFamiliar = card.consecutiveFamiliar;
    var learningStep = card.learningStep;
    var reentryStage = card.reentryStage;
    var learningOrigin = card.learningOrigin;
    String? nextReviewDate;

    switch (rating) {
      case 'FAMILIAR':
        if (learningMode) {
          consecutiveFamiliar += 1;
          final threshold = reentryStage != null && reentryStage > 0
              ? vagueThreshold
              : forgetThreshold;
          if (consecutiveFamiliar >= threshold) {
            learningMode = false;
            consecutiveFamiliar = 0;
            learningStep = 0;
            // 脱离重学：清除学习来源标记
            learningOrigin = null;
            if (reentryStage != null && reentryStage > 0) {
              stage = reentryStage;
              reentryStage = null;
              nextReviewDate = _plusDays(today, _vagueInterval(stage));
            } else {
              stage = 1;
              nextReviewDate = _plusDays(today, 1);
            }
          } else {
            learningStep += 1;
            nextReviewDate = _formatDate(today);
          }
        } else if (stage == 0) {
          stage = 1;
          nextReviewDate = _plusDays(today, 1);
        } else if (stage < maxStage) {
          stage += 1;
          nextReviewDate = _plusDays(today, stageIntervals[stage]);
        } else {
          nextReviewDate = _plusDays(today, stageIntervals[maxStage]);
        }
      case 'FORGET':
        // 学习来源归属：非学习状态进入重学 → 按原状态定来源（新卡=NEW，到期卡=REVIEW）；
        // 重学中再次忘记 → 保持原来源；历史数据（来源为空）兜底按 REVIEW（旧行为归复习队列）。
        if (learningMode) {
          learningOrigin ??= 'REVIEW';
        } else {
          learningOrigin = before == 0 ? 'NEW' : 'REVIEW';
        }
        stage = 0;
        learningMode = true;
        consecutiveFamiliar = 0;
        learningStep = 0;
        reentryStage = null;
        nextReviewDate = _formatDate(today);
      case 'VAGUE':
        final effectiveStage = calculateEffectiveStage(stage, overdueDays);
        if (effectiveStage <= 1) {
          // VAGUE 视同 FORGET，来源逻辑与 FORGET 一致
          if (learningMode) {
            learningOrigin ??= 'REVIEW';
          } else {
            learningOrigin = before == 0 ? 'NEW' : 'REVIEW';
          }
          stage = 0;
          learningMode = true;
          consecutiveFamiliar = 0;
          learningStep = 0;
          reentryStage = null;
          nextReviewDate = _formatDate(today);
        } else {
          // VAGUE 只发生在 stage≥2 的到期卡上，来源必为 REVIEW；
          // 重学中再模糊保持原来源，历史数据兜底 REVIEW。
          if (!learningMode || learningOrigin == null) {
            learningOrigin = 'REVIEW';
          }
          reentryStage = effectiveStage;
          stage = effectiveStage - 1;
          learningMode = true;
          consecutiveFamiliar = 0;
          learningStep = 0;
          nextReviewDate = _formatDate(today);
        }
      default:
        throw ArgumentError.value(rating, 'rating', 'Invalid rating');
    }

    final result = ReviewResult(
      cardId: card.id,
      rating: rating,
      stageBefore: before,
      stageAfter: stage,
      nextReviewDate: nextReviewDate,
      learningMode: learningMode,
      consecutiveFamiliar: consecutiveFamiliar,
      nextIntervalDays: DateTime.parse(nextReviewDate).difference(today).inDays,
      reviewVersion: reviewVersionBefore + 1,
    );

    final updated = FlashCard(
      id: card.id,
      deckId: card.deckId,
      front: card.front,
      back: card.back,
      stage: stage,
      nextReviewDate: nextReviewDate,
      learningMode: learningMode,
      consecutiveFamiliar: consecutiveFamiliar,
      learningStep: learningStep,
      reentryStage: reentryStage,
      learningGoal: card.learningGoal,
      due: !DateTime.parse(nextReviewDate).isAfter(today),
      createdAt: card.createdAt,
      reviewVersion: reviewVersionBefore + 1,
      learningOrigin: learningOrigin,
    );

    return LocalRatingOutcome(
      card: updated,
      result: result,
      wasNewCard: wasNewCard,
      reviewVersionBefore: reviewVersionBefore,
    );
  }

  static int stageInterval(int stage) =>
      SchedulingConstants.stageInterval(stage);

  static int familiarIntervalAfterRating({
    required int stage,
    required bool learningMode,
    required int consecutiveFamiliar,
    required int? reentryStage,
  }) =>
      SchedulingConstants.familiarIntervalAfterRating(
        stage: stage,
        learningMode: learningMode,
        consecutiveFamiliar: consecutiveFamiliar,
        reentryStage: reentryStage,
      );

  static int vagueIntervalAfterRating(int stage) =>
      SchedulingConstants.vagueIntervalAfterRating(stage);

  /// 计算逾期卡的等效 stage。
  ///
  /// 逾期率 ρ = (间隔 + 逾期天数) / 间隔，遗忘程度相当于低了 k = floor(log2(ρ))
  /// 级的卡在同一相对位置的遗忘程度，等效 stage = max(1, stage − k)。
  /// 宽限：逾期 ≤ 2 天或 ρ < 2（未超过一个完整间隔）不罚。
  /// 例：stage 4（7 天）逾期 7 天 → ρ = 2 → 等效 stage 3。
  static int calculateEffectiveStage(int stage, int overdueDays) {
    if (stage <= 1 || overdueDays <= 0) return stage;
    if (overdueDays <= 2) return stage;
    final interval = stageIntervals[stage];
    final elapsed = interval + overdueDays;
    // k = floor(log2(ρ))：k 从 0 递增，直到 elapsed < 2^(k+1) * interval
    var k = 0;
    var threshold = interval * 2;
    while (elapsed >= threshold) {
      k++;
      if (threshold > (1 << 62)) break;
      threshold *= 2;
    }
    return stage - k < 1 ? 1 : stage - k;
  }

  static DateTime calculateToday(DateTime nowUtc, String refreshTime) {
    return _calculateToday(nowUtc, refreshTime);
  }

  static int _vagueInterval(int targetStage) =>
      SchedulingConstants.vagueIntervalForTarget(targetStage);

  static DateTime _calculateToday(DateTime nowUtc, String refreshTime) {
    final businessNow = serverUtcToBusiness(nowUtc);
    final parts = refreshTime.split(':');
    final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '4') ?? 4;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final boundary = DateTime.utc(
      businessNow.year,
      businessNow.month,
      businessNow.day,
      hour,
      minute,
    );
    if (businessNow.isBefore(boundary)) {
      return DateTime(businessNow.year, businessNow.month, businessNow.day - 1);
    }
    return DateTime(businessNow.year, businessNow.month, businessNow.day);
  }

  static String _plusDays(DateTime date, int days) {
    return _formatDate(date.add(Duration(days: days)));
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
