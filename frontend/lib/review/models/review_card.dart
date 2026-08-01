class ReviewCard {
  final String id;
  final String deckId;
  final String front;
  final String? back;
  final int stage;
  final bool learningMode;
  final int consecutiveFamiliar;

  ReviewCard({
    required this.id,
    required this.deckId,
    required this.front,
    this.back,
    required this.stage,
    required this.learningMode,
    required this.consecutiveFamiliar,
  });

  factory ReviewCard.fromJson(Map<String, dynamic> json) {
    return ReviewCard(
      id: json['id'] as String,
      deckId: json['deck_id'] as String,
      front: json['front'] as String,
      back: json['back'] as String?,
      stage: json['stage'] as int? ?? 0,
      learningMode: json['learning_mode'] as bool? ?? false,
      consecutiveFamiliar: json['consecutive_familiar'] as int? ?? 0,
    );
  }
}