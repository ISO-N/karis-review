import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/stats_repository.dart';
import '../models/stats.dart';

final deckStatsProvider = FutureProvider.family<DeckStats, String>((
  ref,
  deckId,
) async {
  return StatsRepository().getDeckStats(deckId);
});
