import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../offline/offline_repository.dart';
import '../../offline/providers.dart';
import '../../sync/providers.dart';
import '../../sync/sync_service.dart';
import '../utils/daily_refresh.dart';

/// 数据版本号：本地 Drift 数据或服务端同步结果发生变化后递增。
final dataVersionProvider = StateProvider<int>((ref) => 0);

class DataRefreshController {
  DataRefreshController(this._sync, this._offline, this._onDataChanged);

  final SyncService _sync;
  final OfflineRepository _offline;
  final void Function() _onDataChanged;

  Timer? _dailyTimer;
  bool _refreshing = false;

  /// 本地写操作完成后通知相关 Provider 重新计算，不发起网络请求。
  void notifyLocalChanged() => _onDataChanged();

  /// 先增量同步，成功后再通知 Provider 从本地数据重算。
  ///
  /// 自动刷新失败时静默保留当前数据，由用户的下拉刷新显式重试。
  Future<void> refreshFromServer({bool force = false}) async {
    if (_refreshing) return;
    final meta = await _offline.getActiveSyncMeta();
    if (meta == null) return;

    _refreshing = true;
    try {
      await _sync.refresh(force: force);
      _onDataChanged();
    } catch (_) {
      // 自动刷新不打断当前页面，也不把网络错误升级成全局错误。
    } finally {
      _refreshing = false;
    }
  }

  /// 按当前用户刷新时间排程下一次自动重算。
  Future<void> armDailyRefresh() async {
    _dailyTimer?.cancel();
    _dailyTimer = null;
    final meta = await _offline.getActiveSyncMeta();
    if (meta == null) return;

    final serverNow = DateTime.now().toUtc().add(
      Duration(milliseconds: meta.clockOffsetMs),
    );
    final delay = nextDailyRefreshDelay(serverNow.toLocal(), meta.refreshTime);
    _dailyTimer = Timer(delay, () {
      unawaited(_onDailyRefresh());
    });
  }

  void cancelDailyRefresh() {
    _dailyTimer?.cancel();
    _dailyTimer = null;
  }

  Future<void> _onDailyRefresh() async {
    await refreshFromServer(force: true);
    await armDailyRefresh();
  }

  void dispose() {
    cancelDailyRefresh();
  }
}

final dataRefreshControllerProvider = Provider<DataRefreshController>((ref) {
  final controller = DataRefreshController(
    ref.watch(syncServiceProvider),
    ref.watch(offlineRepositoryProvider),
    () => ref.read(dataVersionProvider.notifier).state++,
  );
  ref.onDispose(controller.dispose);
  return controller;
});
