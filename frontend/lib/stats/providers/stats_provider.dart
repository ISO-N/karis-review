import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/stats_repository.dart';
import '../models/stats.dart';

class StatsNotifier extends StateNotifier<AsyncValue<OverviewStats?>> {
  final StatsRepository _repository;

  StatsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadOverview();
  }

  Future<void> loadOverview() async {
    state = const AsyncValue.loading();
    try {
      final stats = await _repository.getOverview();
      state = AsyncValue.data(stats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final statsProvider =
    StateNotifierProvider<StatsNotifier, AsyncValue<OverviewStats?>>((ref) {
      return StatsNotifier(StatsRepository());
    });

// Trend provider
final trendProvider = FutureProvider.family<List<TrendPoint>, int>((
  ref,
  days,
) async {
  final repo = StatsRepository();
  return repo.getTrend(days: days);
});
