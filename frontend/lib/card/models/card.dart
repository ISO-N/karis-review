class FlashCard {
  final String id;
  final String deckId;
  final String front;
  final String back;
  final int stage;
  final String? nextReviewDate;
  final bool learningMode;
  final int consecutiveFamiliar;
  final int learningStep;
  final int? reentryStage;
  final int? learningGoal;
  final bool due;
  final String createdAt;

  FlashCard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.stage,
    this.nextReviewDate,
    required this.learningMode,
    this.consecutiveFamiliar = 0,
    this.learningStep = 0,
    this.reentryStage,
    this.learningGoal,
    this.due = false,
    this.createdAt = '',
  });

  factory FlashCard.fromJson(Map<String, dynamic> json) {
    return FlashCard(
      id: json['id'] as String,
      deckId: json['deck_id'] as String? ?? '',
      front: json['front'] as String,
      back: json['back'] as String,
      stage: (json['stage'] as num?)?.toInt() ?? 0,
      nextReviewDate: json['next_review_date'] as String?,
      learningMode: json['learning_mode'] as bool? ?? false,
      consecutiveFamiliar: (json['consecutive_familiar'] as num?)?.toInt() ?? 0,
      learningStep: (json['learning_step'] as num?)?.toInt() ?? 0,
      reentryStage: (json['reentry_stage'] as num?)?.toInt(),
      learningGoal: (json['learning_goal'] as num?)?.toInt(),
      due: json['due'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
