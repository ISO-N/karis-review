import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 全局滚动行为。
///
/// - 桌面 / Web（鼠标、触控板）：纵向滚动区域常驻显示可拖拽的滚动条
///   （thumb 颜色、最小长度等由 `scrollbarTheme` 控制），方便快速定位；
/// - 触屏平台（Android / iOS / fuchsia）：保持默认行为（拖动时叠加显示），
///   不常驻、不占用屏幕空间；
/// - 水平滚动区域（如卡组页的筛选 chips）不显示滚动条，避免视觉噪音。
class KarisScrollBehavior extends MaterialScrollBehavior {
  const KarisScrollBehavior();

  static bool get _isTouchDevice => switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.fuchsia => true,
    _ => false,
  };

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    if (_isTouchDevice) return child;
    switch (details.direction) {
      case AxisDirection.up:
      case AxisDirection.down:
        return Scrollbar(
          controller: details.controller,
          interactive: true,
          thumbVisibility: true,
          trackVisibility: true,
          child: child,
        );
      case AxisDirection.left:
      case AxisDirection.right:
        return child;
    }
  }
}
