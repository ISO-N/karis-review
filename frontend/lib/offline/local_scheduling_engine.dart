import '../card/models/card.dart';
import '../review/models/review_card.dart';
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
  static const List<int> stageIntervals = [0, 1, 2, 4, 7, 15, 30, 90, 180];
  static const int maxStage = 8;
  static const int forgetThreshold = 5;
  static const int vagueThreshold = 3;

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
    var stage = card.stage;
    var learningMode = card.learningMode;
    var consecutiveFamiliar = card.consecutiveFamiliar;
    var learningStep = card.learningStep;
    var reentryStage = card.reentryStage;
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
        stage = 0;
        learningMode = true;
        consecutiveFamiliar = 0;
        learningStep = 0;
        reentryStage = null;
        nextReviewDate = _formatDate(today);
      case 'VAGUE':
        if (stage <= 1) {
          stage = 0;
          learningMode = true;
          consecutiveFamiliar = 0;
          learningStep = 0;
          reentryStage = null;
          nextReviewDate = _formatDate(today);
        } else {
          reentryStage = stage;
          stage -= 1;
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
    );

    return LocalRatingOutcome(
      card: updated,
      result: result,
      wasNewCard: wasNewCard,
      reviewVersionBefore: reviewVersionBefore,
    );
  }

  static int stageInterval(int stage) {
    if (stage < 0 || stage > maxStage) return stageIntervals[maxStage];
    return stageIntervals[stage];
  }

  static int familiarIntervalAfterRating({
    required int stage,
    required bool learningMode,
    required int consecutiveFamiliar,
    required int? reentryStage,
  }) {
    if (learningMode) {
      final threshold = reentryStage != null && reentryStage > 0
          ? vagueThreshold
          : forgetThreshold;
      if (consecutiveFamiliar + 1 >= threshold) {
        if (reentryStage != null && reentryStage > 0) {
          return _vagueInterval(reentryStage);
        }
        return stageIntervals[1];
      }
      return 0;
    }
    if (stage >= maxStage) return stageIntervals[maxStage];
    return stageIntervals[stage + 1];
  }

  static int vagueIntervalAfterRating(int stage) {
    if (stage <= 1) return 0;
    return stageIntervals[stage];
  }

  static DateTime calculateToday(DateTime nowUtc, String refreshTime) {
    return _calculateToday(nowUtc, refreshTime);
  }

  static int _vagueInterval(int targetStage) {
    return stageIntervals[targetStage] - stageIntervals[targetStage - 1];
  }

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
