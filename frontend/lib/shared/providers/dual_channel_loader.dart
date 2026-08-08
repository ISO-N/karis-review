import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../offline/offline_repository.dart';
import '../../sync/sync_service.dart';

/// 双通道加载编排（架构评审 C1，2026-08-08）。
///
/// Card/Deck/Stats 三个 Notifier 的「在线/离线双路径加载骨架」此前整段重复
/// （构造时 offline != null ? _loadLocal() : load()；load 内
/// getActiveSyncMeta → meta==null 走在线 → sync.refresh + 本地读；
/// previous 保留旧值防闪；异常回退旧值）。本类收敛该骨架：
/// 调用方只提供在线/本地 fetch 与状态写入回调。
///
/// 行为语义（与三份旧实现逐行等价）：
/// - previous 为 null 时先置 loading；
/// - 无 offline 或未登录（meta == null）→ 走在线 fetch；
/// - 离线已登录 → sync.refresh() 后走本地 fetch；
/// - 异常：有 previous 保留旧值，无 previous 置 error。
/// - [isStale] 返回 true 时丢弃本次结果（请求版本防抖，CardList 需要）。
class DualChannelLoader {
  DualChannelLoader({
    required this.offline,
    required this.sync,
  });

  final OfflineRepository? offline;
  final SyncService? sync;

  /// 执行一次双通道加载。
  ///
  /// [isStale]：结果落地前再检查一次是否已被更新的请求取代（CardList 的
  /// requestVersion 防抖）；返回 true 则丢弃。默认恒 false（Deck/Stats 无防抖）。
  Future<T?> load<T>({
    required Future<T> Function() fetchOnline,
    required Future<T> Function(String userId) fetchLocal,
    required void Function(AsyncValue<T>) setState,
    required AsyncValue<T> currentState,
    bool Function()? isStale,
  }) async {
    final previous = currentState.valueOrNull;
    if (previous == null) {
      setState(const AsyncValue.loading());
    }
    final stale = isStale ?? () => false;
    try {
      if (offline != null) {
        final meta = await offline!.getActiveSyncMeta();
        if (meta == null) {
          final data = await fetchOnline();
          if (stale()) return data;
          setState(AsyncValue.data(data));
          return data;
        }
        await sync!.refresh();
        if (stale()) return null;
        final data = await fetchLocal(meta.userId);
        if (stale()) return data;
        setState(AsyncValue.data(data));
        return data;
      }
      final data = await fetchOnline();
      if (stale()) return data;
      setState(AsyncValue.data(data));
      return data;
    } catch (e, st) {
      if (stale()) return null;
      if (previous == null) {
        setState(AsyncValue.error(e, st));
      } else {
        setState(AsyncValue.data(previous));
      }
      return null;
    }
  }
}
