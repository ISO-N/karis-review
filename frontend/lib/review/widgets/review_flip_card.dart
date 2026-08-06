import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/utils/motion.dart';

class ReviewFlipCard extends StatefulWidget {
  final bool flipped;
  final VoidCallback onTap;
  final Widget front;
  final Widget back;
  final String semanticsLabel;

  const ReviewFlipCard({
    super.key,
    required this.flipped,
    required this.onTap,
    required this.front,
    required this.back,
    required this.semanticsLabel,
  });

  @override
  State<ReviewFlipCard> createState() => _ReviewFlipCardState();
}

class _ReviewFlipCardState extends State<ReviewFlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: KarisMotion.flip,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: KarisMotion.easeInOut,
    );
    if (widget.flipped) _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant ReviewFlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flipped != widget.flipped) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = widget.flipped ? 1 : 0;
      } else {
        _controller.animateTo(
          widget.flipped ? 1 : 0,
          duration: KarisMotion.flip,
          curve: KarisMotion.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel,
      button: true,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            final angle = _animation.value * math.pi;
            final showBack = angle >= math.pi / 2;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: showBack
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(math.pi),
                      child: widget.back,
                    )
                  : widget.front,
            );
          },
        ),
      ),
    );
  }
}

class ReviewCardFrame extends StatelessWidget {
  final Widget child;
  final bool back;

  const ReviewCardFrame({super.key, required this.child, this.back = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.hairline),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF000000) : const Color(0xFF202B27))
                .withValues(alpha: isDark ? 0.5 : 0.08),
            blurRadius: 34,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}
