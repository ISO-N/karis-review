import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../utils/motion.dart';

class StageRuler extends StatelessWidget {
  final List<int>? distribution;
  final int? currentStage;
  final bool compact;
  final Color? currentColor;

  const StageRuler({
    super.key,
    this.distribution,
    this.currentStage,
    this.compact = false,
    this.currentColor,
  });

  @override
  Widget build(BuildContext context) {
    final values = distribution ?? List.filled(9, 0);
    final maxValue = values.fold<int>(
      1,
      (max, value) => value > max ? value : max,
    );
    final color = currentColor ?? KarisColors.jade;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(9, (index) {
        final highlight = currentStage == index;
        final value = index < values.length ? values[index] : 0;
        final hasValue = value > 0;
        final ratio = value / maxValue;
        final height = compact
            ? (highlight ? 22.0 : 14.0)
            : (highlight ? 38.0 : 24.0 + ratio * 14);
        // 分布模式（无 currentStage）下按占比在 jade 色系内渐变，
        // 长度与颜色双通道编码：占比越高颜色越深；无卡阶段保持灰色。
        final barColor = highlight
            ? color
            : hasValue
            ? Color.lerp(
                KarisColors.jadeSoft,
                KarisColors.jade,
                ratio.clamp(0.0, 1.0),
              )!
            : KarisColors.hairline;
        final labelColor = highlight || hasValue
            ? KarisColors.ink
            : KarisColors.stone;
        final labelWeight = highlight || hasValue
            ? FontWeight.w600
            : FontWeight.w400;
        final label =
            hasValue ? '${KarisTheme.stageName(index)} · $value 张' : null;
        return Expanded(
          child: Semantics(
            label: label,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: reducedDuration(
                    context,
                    const Duration(milliseconds: 350),
                  ),
                  width: 2,
                  height: height,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: compact ? 5 : 7),
                Text(
                  KarisTheme.stageLabels[index],
                  style: karisMono(
                    fontSize: compact ? 8 : 9,
                    color: labelColor,
                    weight: labelWeight,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class MiniStageRuler extends StatelessWidget {
  final List<int> distribution;

  const MiniStageRuler({super.key, required this.distribution});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(9, (index) {
        final active = index < distribution.length && distribution[index] > 0;
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: active ? KarisColors.jade : KarisColors.hairline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
