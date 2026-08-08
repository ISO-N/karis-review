class ReviewCard {
  static const List<int> _intervals = [0, 1, 2, 4, 7, 15, 30, 90, 180];

  final String id;
  final String deckId;
  final String front;
  final String? back;
  final int stage;
  final bool learningMode;
  final int consecutiveFamiliar;
  final int learningStep;
  final int? reentryStage;
  final String? nextReviewDate;
  final int reviewVersion;
  final String? learningOrigin;

  ReviewCard({
    required this.id,
    required this.deckId,
    required this.front,
    this.back,
    required this.stage,
    required this.learningMode,
    required this.consecutiveFamiliar,
    this.learningStep = 0,
    this.reentryStage,
    this.nextReviewDate,
    this.reviewVersion = 0,
    this.learningOrigin,
  });

  int get learningGoal =>
      learningMode ? (reentryStage != null && reentryStage! > 0 ? 3 : 5) : 5;

  int get currentIntervalDays => _intervals[stage.clamp(0, 8)];

  int get familiarIntervalDays {
    if (learningMode) {
      final threshold = reentryStage != null && reentryStage! > 0 ? 3 : 5;
      if (consecutiveFamiliar + 1 >= threshold) {
        final target = reentryStage;
        if (target != null && target > 0) {
          return _intervals[target] - _intervals[target - 1];
        }
        return _intervals[1];
      }
      return 0;
    }
    if (stage >= 8) return _intervals[8];
    return _intervals[stage + 1];
  }

  int get vagueIntervalDays => stage <= 1 ? 0 : _intervals[stage];

  factory ReviewCard.fromJson(Map<String, dynamic> json) {
    return ReviewCard(
      id: json['id'] as String,
      deckId: json['deck_id'] as String,
      front: json['front'] as String,
      back: json['back'] as String?,
      stage: (json['stage'] as num?)?.toInt() ?? 0,
      learningMode: json['learning_mode'] as bool? ?? false,
      consecutiveFamiliar: (json['consecutive_familiar'] as num?)?.toInt() ?? 0,
      learningStep: (json['learning_step'] as num?)?.toInt() ?? 0,
      reentryStage: (json['reentry_stage'] as num?)?.toInt(),
      nextReviewDate: json['next_review_date'] as String?,
      reviewVersion: (json['review_version'] as num?)?.toInt() ?? 0,
      learningOrigin: json['learning_origin'] as String?,
    );
  }
}

class ReviewResult {
  final String cardId;
  final String rating;
  final int stageBefore;
  final int stageAfter;
  final String? nextReviewDate;
  final bool learningMode;
  final int consecutiveFamiliar;
  final int nextIntervalDays;
  final int reviewVersion;

  ReviewResult({
    required this.cardId,
    required this.rating,
    required this.stageBefore,
    required this.stageAfter,
    this.nextReviewDate,
    required this.learningMode,
    required this.consecutiveFamiliar,
    required this.nextIntervalDays,
    this.reviewVersion = 0,
  });

  factory ReviewResult.fromJson(Map<String, dynamic> json) {
    return ReviewResult(
      cardId: json['card_id'] as String,
      rating: json['rating'] as String,
      stageBefore: (json['stage_before'] as num?)?.toInt() ?? 0,
      stageAfter: (json['stage_after'] as num?)?.toInt() ?? 0,
      nextReviewDate: json['next_review_date'] as String?,
      learningMode: json['learning_mode'] as bool? ?? false,
      consecutiveFamiliar: (json['consecutive_familiar'] as num?)?.toInt() ?? 0,
      nextIntervalDays: (json['next_interval_days'] as num?)?.toInt() ?? 0,
      reviewVersion: (json['review_version'] as num?)?.toInt() ?? 0,
    );
  }
}
