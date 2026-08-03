import 'dart:async';

import 'package:flutter/widgets.dart';

/// 路由变化时触发一次静默刷新。
///
/// 不按页面名过滤，依赖 [DataRefreshController] 内部对无用户/无同步元数据的
/// 空转判断，以及 `SyncService` 已有的冷却和单飞行机制避免重复请求。
class AutoRefreshNavigatorObserver extends NavigatorObserver {
  AutoRefreshNavigatorObserver({required this.onDataRouteChanged});

  final Future<void> Function() onDataRouteChanged;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _refresh();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _refresh();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _refresh();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _refresh();
  }

  void _refresh() {
    unawaited(onDataRouteChanged());
  }
}
