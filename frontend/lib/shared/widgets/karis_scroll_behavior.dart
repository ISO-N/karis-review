import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 全局滚动行为。
///
/// - 桌面 / Web（鼠标、触控板）：纵向滚动区域常驻显示可拖拽的滚动条
///   （thumb 颜色、最小长度等由 `scrollbarTheme` 控制），方便快速定位；
/// - 触屏平台（Android / iOS / fuchsia，含手机浏览器 Web）：同样添加
///   Scrollbar 但使用 overlay 行为——不常驻、不占屏幕空间，拖动时叠加显示
///   滚动位置指示（Flutter Web 触屏没有浏览器原生滚动条，若不添加则完全
///   看不到滚动进度）；
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
    switch (details.direction) {
      case AxisDirection.up:
      case AxisDirection.down:
        final precise = !_isTouchDevice;
        return Scrollbar(
          controller: details.controller,
          // 桌面与触屏均可拖拽 thumb / 点按 track 滚动；
          // 仅常驻/进度显示策略区分（触屏 overlay，桌面常驻）。
          interactive: true,
          thumbVisibility: precise,
          trackVisibility: precise,
          child: child,
        );
      case AxisDirection.left:
      case AxisDirection.right:
        return child;
    }
  }
}
