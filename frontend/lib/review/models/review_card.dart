import '../../shared/scheduling/scheduling_constants.dart';

class ReviewCard {

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

  int get learningGoal => learningMode
      ? SchedulingConstants.relearningThreshold(reentryStage)
      : SchedulingConstants.forgetThreshold;

  int get currentIntervalDays => SchedulingConstants.stageInterval(stage);

  int get familiarIntervalDays =>
      SchedulingConstants.familiarIntervalAfterRating(
        stage: stage,
        learningMode: learningMode,
        consecutiveFamiliar: consecutiveFamiliar,
        reentryStage: reentryStage,
      );

  int get vagueIntervalDays => SchedulingConstants.vagueIntervalAfterRating(stage);

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
  final int? reentryStage;
  final String? learningOrigin;

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
    this.reentryStage,
    this.learningOrigin,
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
      reentryStage: (json['reentry_stage'] as num?)?.toInt(),
      learningOrigin: json['learning_origin'] as String?,
    );
  }
}
