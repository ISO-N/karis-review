import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../app/theme.dart';
import '../utils/motion.dart';

/// 签名元素：记忆刻度环（Memory Ring）。
///
/// 以"年轮 / 刻度盘"隐喻承载"间隔重复、记忆强度、复习进度"的产品本质。
/// 进度弧自 12 点方向顺时针生长，外缘配一圈细刻度线，使其区别于通用的
/// 圆形进度条——刻度的存在让"记忆刻度"这一主题真正立起来。
///
/// 克制：单色 jade 弧 + hairline 刻度线，无渐变、无发光，保持纸感。
class MemoryRing extends StatelessWidget {
  const MemoryRing({
    super.key,
    required this.progress,
    this.size = 72,
    this.strokeWidth = 3,
    this.tickLength = 3,
    this.tickCount = 32,
    this.tickProgress = 1,
    this.color,
    this.trackColor,
    this.tickColor,
    this.duration = KarisMotion.grow,
  });

  /// 进度 0.0 ~ 1.0，会被 clamp。
  final double progress;

  /// 刻度点亮进度 0.0 ~ 1.0：只点亮前 [tickProgress] 比例的刻度线。
  ///
  /// 默认 1 全部点亮；完成场景可驱动它让刻度依次亮起（如复习完成页
  /// 外缘刻度级联点亮后落章）。非 0..1 值会被 clamp。
  final double tickProgress;

  /// 外径（直径）。
  final double size;

  /// 进度弧线宽。
  final double strokeWidth;

  /// 刻度线长度（向环外延伸）。
  final double tickLength;

  /// 刻度线数量。非正数时不绘制刻度，退化为普通圆环。
  final int tickCount;

  /// 进度弧颜色，默认语义 jade。
  final Color? color;

  /// 底环颜色，默认语义 hairline。
  final Color? trackColor;

  /// 刻度线颜色，默认语义 stone（弱化）。
  final Color? tickColor;

  /// 生长动画时长，默认 [KarisMotion.grow]。
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    final c = color ?? colors.jade;
    final track = trackColor ?? colors.hairline;
    final tick = tickColor ?? colors.stone.withValues(alpha: 0.5);
    final clamped = progress.clamp(0.0, 1.0);
    final litTicks = tickProgress.clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: clamped),
        duration: reducedDuration(context, duration),
        curve: KarisMotion.easeOut,
        builder: (context, value, _) => CustomPaint(
          painter: _MemoryRingPainter(
            progress: value,
            strokeWidth: strokeWidth,
            tickLength: tickLength,
            tickCount: tickCount,
            tickProgress: litTicks,
            color: c,
            trackColor: track,
            tickColor: tick,
          ),
        ),
      ),
    );
  }
}

class _MemoryRingPainter extends CustomPainter {
  _MemoryRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.tickLength,
    required this.tickCount,
    required this.tickProgress,
    required this.color,
    required this.trackColor,
    required this.tickColor,
  });

  final double progress;
  final double strokeWidth;
  final double tickLength;
  final int tickCount;

  /// 刻度点亮进度：只绘制前 tickCount * tickProgress 根刻度。
  final double tickProgress;
  final Color color;
  final Color trackColor;
  final Color tickColor;

  static const double _startAngle = -1.5708; // 12 点方向（-π/2）

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    // 环的实际绘制半径：让进度弧紧贴外缘刻度线内侧，避免与刻度重叠。
    final arcRadius = radius - tickLength - strokeWidth / 2;

    final arcRect = Rect.fromCircle(center: center, radius: arcRadius);
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    // 底环。
    canvas.drawCircle(center, arcRadius, trackPaint);

    // 进度弧：自 12 点方向顺时针扫过 progress * 2π。
    if (progress > 0) {
      final sweep = progress * 6.2832;
      canvas.drawArc(arcRect, _startAngle, sweep, false, arcPaint);
    }

    // 外缘刻度线：tickCount 根，顺时针均匀分布；
    // 由 tickProgress 控制点亮前几根（完成场景的级联点亮效果）。
    if (tickCount > 0) {
      final tickPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = tickColor;
      final litCount = tickCount * tickProgress;
      for (var i = 0; i < tickCount; i++) {
        if (i >= litCount) break;
        final angle = _startAngle + i * (6.2832 / tickCount);
        final cosA = math.cos(angle);
        final sinA = math.sin(angle);
        final inner = Offset(center.dx + cosA * (radius - tickLength),
            center.dy + sinA * (radius - tickLength));
        final outer =
            Offset(center.dx + cosA * radius, center.dy + sinA * radius);
        canvas.drawLine(inner, outer, tickPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_MemoryRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.tickLength != tickLength ||
        oldDelegate.tickCount != tickCount ||
        oldDelegate.tickProgress != tickProgress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.tickColor != tickColor;
  }
}
