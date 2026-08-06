import 'package:flutter/widgets.dart';

/// Karis Review 统一动效 tokens。
///
/// 所有动画时长/缓动必须从这里取，禁止在页面散落时间常量。
/// 全部时长遵守「快进快出、慢进慢出」原则，不引入漂浮感。
abstract final class KarisMotion {
  /// 按压反馈（按钮/卡片按下收缩）。
  static const Duration press = Duration(milliseconds: 120);

  /// Toast / Banner / 状态 chip 淡入淡出。
  static const Duration feedback = Duration(milliseconds: 180);

  /// 评分后当前卡退出、下一张进入。
  static const Duration cardSwitch = Duration(milliseconds: 240);

  /// 路由切换淡入 + 位移。
  static const Duration page = Duration(milliseconds: 260);

  /// 3D 翻面。
  static const Duration flip = Duration(milliseconds: 480);

  /// 图表生长、完成进度环、庆祝收尾。
  static const Duration grow = Duration(milliseconds: 600);

  /// 列表入场交错步进（相邻项间隔）。
  static const Duration staggerStep = Duration(milliseconds: 40);

  /// 骨架屏流光扫过（循环）。
  static const Duration shimmer = Duration(milliseconds: 1200);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve springy = Curves.easeOutBack;

  /// 第 [index] 个列表项的入场延迟（`index * staggerStep`）。
  static Duration staggerDelay(int index) =>
      Duration(milliseconds: index * staggerStep.inMilliseconds);
}

/// prefers-reduced-motion：开启时动画时长归零（保留状态切换）。
Duration reducedDuration(BuildContext context, Duration duration) {
  return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}

/// prefers-reduced-motion：开启时为 0，否则为 [value]。
double reducedValue(BuildContext context, double value) {
  return MediaQuery.disableAnimationsOf(context) ? 0 : value;
}
