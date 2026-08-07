import 'package:flutter/widgets.dart';

import '../../app/theme.dart';
import 'memory_ring.dart';

/// 品牌字标：Karis 的衬线 "K" 章。
///
/// 提炼自登录页的品牌横条，作为可复用的品牌锚点。默认是一个 ink 圆角
/// 横条内嵌衬线 "K"；设置 [showRing] 后会在外侧叠一圈记忆刻度环，
/// 与 [MemoryRing] 组成"Karis + 记忆刻度"的品牌签名。
class KarisGlyph extends StatelessWidget {
  const KarisGlyph({
    super.key,
    this.height = 26,
    this.glyphSize = 18,
    this.borderRadius = 6,
    this.showRing = false,
  });

  /// 字标横条高度。
  final double height;

  /// 内嵌 "K" 字号。
  final double glyphSize;

  /// 圆角。
  final double borderRadius;

  /// 是否在字标外叠加一圈记忆刻度环。
  final bool showRing;

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    final k = Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.ink,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        'K',
        style: TextStyle(
          color: colors.surface,
          fontFamily: KarisTheme.displayFamily,
          fontSize: glyphSize,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );

    if (!showRing) return k;

    // 记忆刻度环环绕：环只做装饰，不承载语义，故包 ExcludeSemantics 避免
    // 屏幕阅读器重复朗读。半圈刻度（progress 0.5）指向"记忆刻度"母题。
    return ExcludeSemantics(
      child: SizedBox(
        width: height + 16,
        height: height + 16,
        child: Stack(
          alignment: Alignment.center,
          children: [
            MemoryRing(
              progress: 0.5,
              size: height + 16,
              strokeWidth: 1.5,
              tickLength: 2.5,
              tickCount: 24,
            ),
            k,
          ],
        ),
      ),
    );
  }
}
