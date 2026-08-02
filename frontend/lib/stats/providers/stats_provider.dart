import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../offline/offline_repository.dart';
import '../../offline/providers.dart';
import '../../sync/providers.dart';
import '../../sync/sync_service.dart';
import '../repositories/stats_repository.dart';
import '../models/stats.dart';

class StatsNotifier extends StateNotifier<AsyncValue<OverviewStats?>> {
  final StatsRepository _repository;
  final OfflineRepository? offline;
  final SyncService? sync;

  StatsNotifier(this._repository, {this.offline, this.sync})
    : super(const AsyncValue.loading()) {
    if (offline != null) {
      _loadLocal();
    } else {
      loadOverview();
    }
  }

  Future<void> loadOverview() async {
    if (offline != null) {
      final previous = state.valueOrNull;
      if (previous == null) {
        state = const AsyncValue.loading();
      }
      try {
        final meta = await offline!.getActiveSyncMeta();
        if (meta == null) {
          state = AsyncValue.data(await _repository.getOverview());
          return;
        }
        await sync!.refresh();
        state = AsyncValue.data(await offline!.getOverviewStats(meta.userId));
      } catch (e, st) {
        if (previous == null) {
          state = AsyncValue.error(e, st);
        } else {
          state = AsyncValue.data(previous);
        }
      }
      return;
    }

    state = const AsyncValue.loading();
    try {
      final stats = await _repository.getOverview();
      state = AsyncValue.data(stats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _loadLocal() async {
    try {
      final meta = await offline!.getActiveSyncMeta();
      if (meta == null) return;
      state = AsyncValue.data(await offline!.getOverviewStats(meta.userId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final statsProvider =
    StateNotifierProvider<StatsNotifier, AsyncValue<OverviewStats?>>((ref) {
      return StatsNotifier(
        StatsRepository(),
        offline: ref.watch(offlineRepositoryProvider),
        sync: ref.watch(syncServiceProvider),
      );
    });

final trendProvider = FutureProvider.family<List<TrendPoint>, int>((
  ref,
  days,
) async {
  final offline = ref.watch(offlineRepositoryProvider);
  final meta = await offline.getActiveSyncMeta();
  if (meta == null) {
    return StatsRepository().getTrend(days: days);
  }
  return offline.getTrend(meta.userId, days: days);
});
