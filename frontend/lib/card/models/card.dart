class FlashCard {
  final String id;
  final String front;
  final String back;
  final int stage;
  final String? nextReviewDate;
  final bool learningMode;
  final String createdAt;

  FlashCard({
    required this.id,
    required this.front,
    required this.back,
    required this.stage,
    this.nextReviewDate,
    required this.learningMode,
    required this.createdAt,
  });

  factory FlashCard.fromJson(Map<String, dynamic> json) {
    return FlashCard(
      id: json['id'] as String,
      front: json['front'] as String,
      back: json['back'] as String,
      stage: json['stage'] as int? ?? 0,
      nextReviewDate: json['next_review_date'] as String?,
      learningMode: json['learning_mode'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}