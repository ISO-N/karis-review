import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../offline/offline_repository.dart';
import '../../offline/providers.dart';
import '../../shared/providers/data_refresh_provider.dart';
import '../../sync/providers.dart';
import '../../sync/sync_service.dart';
import '../repositories/stats_repository.dart';
import '../models/stats.dart';

class StatsNotifier extends StateNotifier<AsyncValue<OverviewStats?>> {
  final StatsRepository _repository;
  final OfflineRepository? offline;
  final SyncService? sync;

  /// 概览数据新鲜度窗口：窗口内进入页面直接复用内存缓存，不触发网络同步。
  static const Duration _cacheTtl = Duration(minutes: 5);

  DateTime? _lastLoadedAt;

  /// 正在刷新中的标志：导航预取与页面 initState 可能先后触发，
  /// 第二次调用直接返回 false，避免并发执行两次 sync.refresh()。
  bool _inFlight = false;

  StatsNotifier(this._repository, {this.offline, this.sync})
    : super(const AsyncValue.loading()) {
    if (offline != null) {
      _loadLocal();
    } else {
      loadOverview();
    }
  }

  bool get _isFresh {
    final last = _lastLoadedAt;
    if (last == null) return false;
    return DateTime.now().difference(last) < _cacheTtl;
  }

  /// 加载今日概览。返回是否真的发生了刷新：
  /// - 命中新鲜度窗口（且非 [force]）或已有刷新在途时直接跳过，返回 false；
  /// - 刷新成功返回 true，供页面决定是否需要联动刷新趋势图。
  /// 离线模式下已有数据时不置 loading，旧数据保持可见、后台静默同步。
  Future<bool> loadOverview({bool force = false}) async {
    if (_inFlight) return false;
    if (!force && _isFresh) return false;
    _inFlight = true;
    try {
      if (offline != null) {
        final previous = state.valueOrNull;
        if (previous == null) {
          state = const AsyncValue.loading();
        }
        try {
          final meta = await offline!.getActiveSyncMeta();
          if (meta == null) {
            state = AsyncValue.data(await _repository.getOverview());
            _lastLoadedAt = DateTime.now();
            return true;
          }
          await sync!.refresh();
          state = AsyncValue.data(await offline!.getOverviewStats(meta.userId));
          _lastLoadedAt = DateTime.now();
          return true;
        } catch (e, st) {
          if (previous == null) {
            state = AsyncValue.error(e, st);
          } else {
            state = AsyncValue.data(previous);
          }
          return false;
        }
      }

      state = const AsyncValue.loading();
      try {
        final stats = await _repository.getOverview();
        state = AsyncValue.data(stats);
        _lastLoadedAt = DateTime.now();
        return true;
      } catch (e, st) {
        state = AsyncValue.error(e, st);
        return false;
      }
    } finally {
      _inFlight = false;
    }
  }

  Future<void> _loadLocal() async {
    try {
      final meta = await offline!.getActiveSyncMeta();
      if (meta == null) return;
      state = AsyncValue.data(await offline!.getOverviewStats(meta.userId));
      _lastLoadedAt = DateTime.now();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> reloadAfterDataChange() async {
    if (offline == null) {
      // 数据变更（dataVersionProvider 变化）需绕过 TTL 强制刷新。
      await loadOverview(force: true);
      return;
    }
    final meta = await offline!.getActiveSyncMeta();
    if (meta == null) {
      await loadOverview(force: true);
      return;
    }
    await _loadLocal();
  }
}

final statsProvider =
    StateNotifierProvider<StatsNotifier, AsyncValue<OverviewStats?>>((ref) {
      final notifier = StatsNotifier(
        StatsRepository(),
        offline: ref.watch(offlineRepositoryProvider),
        sync: ref.watch(syncServiceProvider),
      );
      ref.listen(dataVersionProvider, (_, _) {
        unawaited(notifier.reloadAfterDataChange());
      });
      return notifier;
    });

final trendProvider = FutureProvider.family<List<TrendPoint>, int>((
  ref,
  days,
) async {
  ref.watch(dataVersionProvider);
  final offline = ref.watch(offlineRepositoryProvider);
  final meta = await offline.getActiveSyncMeta();
  if (meta == null) {
    return StatsRepository().getTrend(days: days);
  }
  return offline.getTrend(meta.userId, days: days);
});
