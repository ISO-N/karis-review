import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// 纸张纹理：极低对比度噪点层，让「纸墨」从隐喻走向体感。
///
/// 克制约定（违反任何一条都应退回纯色）：
/// - 点密度与 alpha 压到最低：肉眼几乎不可见，但去掉后页面会「发秃」；
/// - 静态绘制、零动画：配合 [RepaintBoundary] 只光栅化一次，
///   滚动、切页、评分时零重绘成本（桌面端性能红线）；
/// - 亮暗主题各取确定性种子，主题切换时颗粒不「跳动」；
/// - 全局覆盖在内容之上：表面/卡片同样带纸纹，视觉统一；
///   alpha 极低，不影响文字与图形的清晰度。
class PaperTexture extends StatelessWidget {
  const PaperTexture({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _PaperTexturePainter(
            dotColor: isDark ? Colors.white : colors.ink,
          ),
        ),
      ),
    );
  }
}

class _PaperTexturePainter extends CustomPainter {
  _PaperTexturePainter({required this.dotColor});

  final Color dotColor;

  /// 固定种子：亮暗主题使用同一套颗粒分布，避免切换时跳变。
  static const int _seed = 20260808;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final random = math.Random(_seed);
    final paint = Paint()..color = dotColor.withValues(alpha: 0.028);
    // 每 ~2600 px² 一颗点：1080p 全屏约 800 颗，颗粒感足够且不糊。
    final count = ((size.width * size.height) / 2600).clamp(260, 900).toInt();
    for (var i = 0; i < count; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = 0.4 + random.nextDouble() * 0.7;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PaperTexturePainter oldDelegate) {
    return oldDelegate.dotColor != dotColor;
  }
}
