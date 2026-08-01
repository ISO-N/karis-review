class OverviewStats {
  final int totalCards;
  final int totalDecks;
  final int dueToday;
  final int reviewedToday;
  final int learnedToday;
  final int masteredCards;
  final int learningCards;

  OverviewStats({
    required this.totalCards,
    required this.totalDecks,
    required this.dueToday,
    required this.reviewedToday,
    required this.learnedToday,
    required this.masteredCards,
    required this.learningCards,
  });

  factory OverviewStats.fromJson(Map<String, dynamic> json) {
    return OverviewStats(
      totalCards: (json['total_cards'] as num?)?.toInt() ?? 0,
      totalDecks: (json['total_decks'] as num?)?.toInt() ?? 0,
      dueToday: (json['due_today'] as num?)?.toInt() ?? 0,
      reviewedToday: (json['reviewed_today'] as num?)?.toInt() ?? 0,
      learnedToday: (json['learned_today'] as num?)?.toInt() ?? 0,
      masteredCards: (json['mastered_cards'] as num?)?.toInt() ?? 0,
      learningCards: (json['learning_cards'] as num?)?.toInt() ?? 0,
    );
  }
}

class DeckStats {
  final String deckId;
  final String deckName;
  final int totalCards;
  final int dueToday;
  final int reviewedToday;
  final Map<String, int> stageDistribution;

  DeckStats({
    required this.deckId,
    required this.deckName,
    required this.totalCards,
    required this.dueToday,
    required this.reviewedToday,
    required this.stageDistribution,
  });

  factory DeckStats.fromJson(Map<String, dynamic> json) {
    final dist = json['stage_distribution'] as Map<String, dynamic>? ?? {};
    return DeckStats(
      deckId: json['deck_id'] as String? ?? '',
      deckName: json['deck_name'] as String? ?? '',
      totalCards: (json['total_cards'] as num?)?.toInt() ?? 0,
      dueToday: (json['due_today'] as num?)?.toInt() ?? 0,
      reviewedToday: (json['reviewed_today'] as num?)?.toInt() ?? 0,
      stageDistribution: dist.map((k, v) => MapEntry(k, (v as num).toInt())),
    );
  }
}

class TrendPoint {
  final String date;
  final int reviewed;
  final int learned;

  TrendPoint({required this.date, required this.reviewed, required this.learned});

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      date: json['date'] as String? ?? '',
      reviewed: (json['reviewed'] as num?)?.toInt() ?? 0,
      learned: (json['learned'] as num?)?.toInt() ?? 0,
    );
  }
}