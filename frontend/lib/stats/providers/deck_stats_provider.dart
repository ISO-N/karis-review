import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../offline/providers.dart';
import '../../shared/providers/data_refresh_provider.dart';
import '../repositories/stats_repository.dart';
import '../models/stats.dart';

final deckStatsProvider = FutureProvider.family<DeckStats, String>((
  ref,
  deckId,
) async {
  ref.watch(dataVersionProvider);
  final offline = ref.watch(offlineRepositoryProvider);
  final meta = await offline.getActiveSyncMeta();
  if (meta == null) {
    return StatsRepository().getDeckStats(deckId);
  }
  return offline.getDeckStats(meta.userId, deckId);
});
