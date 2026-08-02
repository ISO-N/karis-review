class Deck {
  final String id;
  final String name;
  final int cardCount;
  final int dueCount;
  final int newCount;
  final int masteredCount;
  final List<int> stageDistribution;
  final List<int> dueStageDistribution;
  final String createdAt;

  Deck({
    required this.id,
    required this.name,
    required this.cardCount,
    required this.dueCount,
    this.newCount = 0,
    this.masteredCount = 0,
    List<int>? stageDistribution,
    List<int>? dueStageDistribution,
    this.createdAt = '',
  }) : stageDistribution = stageDistribution ?? List.filled(9, 0),
       dueStageDistribution = dueStageDistribution ?? List.filled(9, 0);

  factory Deck.fromJson(Map<String, dynamic> json) {
    return Deck(
      id: json['id'] as String,
      name: json['name'] as String,
      cardCount: (json['card_count'] as num?)?.toInt() ?? 0,
      dueCount: (json['due_count'] as num?)?.toInt() ?? 0,
      newCount: (json['new_count'] as num?)?.toInt() ?? 0,
      masteredCount: (json['mastered_count'] as num?)?.toInt() ?? 0,
      stageDistribution: _parseDistribution(json['stage_distribution']),
      dueStageDistribution: _parseDistribution(json['due_stage_distribution']),
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  static List<int> _parseDistribution(dynamic value) {
    final result = List.filled(9, 0);
    if (value is Map) {
      for (final entry in value.entries) {
        final index = int.tryParse('${entry.key}');
        if (index != null && index >= 0 && index < 9) {
          result[index] = (entry.value as num?)?.toInt() ?? 0;
        }
      }
    }
    return result;
  }
}
