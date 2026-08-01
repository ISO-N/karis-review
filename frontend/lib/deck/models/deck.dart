class Deck {
  final String id;
  final String name;
  final int cardCount;
  final int dueCount;
  final String createdAt;

  Deck({
    required this.id,
    required this.name,
    required this.cardCount,
    required this.dueCount,
    required this.createdAt,
  });

  factory Deck.fromJson(Map<String, dynamic> json) {
    return Deck(
      id: json['id'] as String,
      name: json['name'] as String,
      cardCount: json['card_count'] as int? ?? 0,
      dueCount: json['due_count'] as int? ?? 0,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}