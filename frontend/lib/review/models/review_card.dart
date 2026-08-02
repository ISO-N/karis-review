class ReviewCard {
  final String id;
  final String deckId;
  final String front;
  final String? back;
  final int stage;
  final bool learningMode;
  final int consecutiveFamiliar;
  final int learningStep;
  final int learningGoal;
  final int? reentryStage;
  final String? nextReviewDate;
  final int currentIntervalDays;
  final int familiarIntervalDays;
  final int vagueIntervalDays;
  final int reviewVersion;

  ReviewCard({
    required this.id,
    required this.deckId,
    required this.front,
    this.back,
    required this.stage,
    required this.learningMode,
    required this.consecutiveFamiliar,
    this.learningStep = 0,
    this.learningGoal = 5,
    this.reentryStage,
    this.nextReviewDate,
    this.currentIntervalDays = 0,
    this.familiarIntervalDays = 0,
    this.vagueIntervalDays = 0,
    this.reviewVersion = 0,
  });

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
      learningGoal: (json['learning_goal'] as num?)?.toInt() ?? 5,
      reentryStage: (json['reentry_stage'] as num?)?.toInt(),
      nextReviewDate: json['next_review_date'] as String?,
      currentIntervalDays:
          (json['current_interval_days'] as num?)?.toInt() ?? 0,
      familiarIntervalDays:
          (json['familiar_interval_days'] as num?)?.toInt() ?? 0,
      vagueIntervalDays: (json['vague_interval_days'] as num?)?.toInt() ?? 0,
      reviewVersion: (json['review_version'] as num?)?.toInt() ?? 0,
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
