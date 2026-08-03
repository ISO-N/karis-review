class OverviewStats {
  final int totalCards;
  final int totalDecks;
  final int dueToday;
  final int reviewedToday;
  final int learnedToday;
  final int masteredCards;
  final int newCards;
  final int learningCards;
  final List<int> stageDistribution;
  final List<int> dueStageDistribution;

  OverviewStats({
    required this.totalCards,
    required this.totalDecks,
    required this.dueToday,
    required this.reviewedToday,
    required this.learnedToday,
    required this.masteredCards,
    required this.newCards,
    required this.learningCards,
    List<int>? stageDistribution,
    List<int>? dueStageDistribution,
  }) : stageDistribution = stageDistribution ?? List.filled(9, 0),
       dueStageDistribution = dueStageDistribution ?? List.filled(9, 0);

  factory OverviewStats.fromJson(Map<String, dynamic> json) {
    return OverviewStats(
      totalCards: (json['total_cards'] as num?)?.toInt() ?? 0,
      totalDecks: (json['total_decks'] as num?)?.toInt() ?? 0,
      dueToday: (json['due_today'] as num?)?.toInt() ?? 0,
      reviewedToday: (json['reviewed_today'] as num?)?.toInt() ?? 0,
      learnedToday: (json['learned_today'] as num?)?.toInt() ?? 0,
      masteredCards: (json['mastered_cards'] as num?)?.toInt() ?? 0,
      newCards: (json['new_cards'] as num?)?.toInt() ?? 0,
      learningCards: (json['learning_cards'] as num?)?.toInt() ?? 0,
      stageDistribution: _parseDistribution(json['stage_distribution']),
      dueStageDistribution: _parseDistribution(json['due_stage_distribution']),
    );
  }

  static List<int> _parseDistribution(dynamic value) {
    final result = List.filled(9, 0);
    if (value is List) {
      for (var i = 0; i < value.length && i < 9; i++) {
        result[i] = (value[i] as num?)?.toInt() ?? 0;
      }
    } else if (value is Map) {
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

class DeckStats {
  final String deckId;
  final String deckName;
  final int totalCards;
  final int dueToday;
  final int reviewedToday;
  final int newCards;
  final int learningCards;
  final int masteredCards;
  final List<int> stageDistribution;
  final List<int> dueStageDistribution;

  DeckStats({
    required this.deckId,
    required this.deckName,
    required this.totalCards,
    required this.dueToday,
    required this.reviewedToday,
    this.newCards = 0,
    this.learningCards = 0,
    this.masteredCards = 0,
    List<int>? stageDistribution,
    List<int>? dueStageDistribution,
  }) : stageDistribution = stageDistribution ?? List.filled(9, 0),
       dueStageDistribution = dueStageDistribution ?? List.filled(9, 0);

  factory DeckStats.fromJson(Map<String, dynamic> json) {
    return DeckStats(
      deckId: json['deck_id'] as String? ?? '',
      deckName: json['deck_name'] as String? ?? '',
      totalCards: (json['total_cards'] as num?)?.toInt() ?? 0,
      dueToday: (json['due_today'] as num?)?.toInt() ?? 0,
      reviewedToday: (json['reviewed_today'] as num?)?.toInt() ?? 0,
      newCards: (json['new_cards'] as num?)?.toInt() ?? 0,
      learningCards: (json['learning_cards'] as num?)?.toInt() ?? 0,
      masteredCards: (json['mastered_cards'] as num?)?.toInt() ?? 0,
      stageDistribution: _parseDistribution(json['stage_distribution']),
      dueStageDistribution: _parseDistribution(json['due_stage_distribution']),
    );
  }

  static List<int> _parseDistribution(dynamic value) {
    final result = List.filled(9, 0);
    if (value is List) {
      for (var i = 0; i < value.length && i < 9; i++) {
        result[i] = (value[i] as num?)?.toInt() ?? 0;
      }
    } else if (value is Map) {
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

class TrendPoint {
  final String date;
  final int reviewed;
  final int learned;

  TrendPoint({
    required this.date,
    required this.reviewed,
    required this.learned,
  });

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      date: json['date'] as String? ?? '',
      reviewed: (json['reviewed'] as num?)?.toInt() ?? 0,
      learned: (json['learned'] as num?)?.toInt() ?? 0,
    );
  }
}
