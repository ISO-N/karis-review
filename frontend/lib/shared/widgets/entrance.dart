import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../utils/motion.dart';

/// 列表项入场动画：淡入 + 上移。
///
/// 用法：列表项包一层，`delay` 传 `KarisMotion.staggerDelay(index)`，
/// 形成逐项递进的「档案翻开」感。
///
/// 性能约定：滚动加载（非首屏）的列表项应传 `play: false` 直接渲染，
/// 避免深层项长延迟 + 大量动画同时播放导致的掉帧；首屏保留交错入场动效。
/// reduced-motion 时同样直接返回子组件。
class KarisEntrance extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Offset offset;
  final Duration duration;

  /// 为 false 时跳过动画直接渲染（零开销，用于滚动加载的列表项）。
  final bool play;

  const KarisEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 8),
    this.duration = KarisMotion.page,
    this.play = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!play || MediaQuery.disableAnimationsOf(context)) return child;
    final total = duration + delay;
    final begin = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: KarisMotion.easeOut,
      child: child,
      builder: (context, t, child) {
        final eased = Curves.easeOut.transform(
          ((t - begin) / (1 - begin)).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: offset * (1 - eased),
            child: child,
          ),
        );
      },
    );
  }
}

/// 按压反馈：按下收缩 [pressedScale]，抬起回弹。
///
/// 用于评分、开始、列表项等「动作」型交互，增强手感。
class KarisPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final BorderRadius? borderRadius;

  const KarisPressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
    this.borderRadius,
  });

  @override
  State<KarisPressable> createState() => _KarisPressableState();
}

class _KarisPressableState extends State<KarisPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: reducedDuration(context, KarisMotion.press),
        curve: KarisMotion.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// 通用骨架屏单元：静态圆角块，无流光动画（避免桌面端持续重绘）。
///
/// 用于加载态替代内联 spinner，减少首屏跳动。
class KarisSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const KarisSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.hairline.withValues(alpha: 0.55),
        borderRadius: borderRadius,
      ),
    );
  }
}

/// 骨架屏容器：包一组 [KarisSkeleton]。
///
/// 刻意不做 shimmer 流光循环——无限循环动画在桌面端持续触发重绘，
/// 切页加载期间与转场动画叠加会掉帧；静态骨架视觉清晰、零动画成本。
class KarisSkeletonGroup extends StatelessWidget {
  final Widget child;

  const KarisSkeletonGroup({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
