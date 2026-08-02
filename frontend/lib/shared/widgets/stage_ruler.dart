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
        final active = currentStage == index;
        final value = index < values.length ? values[index] : 0;
        final ratio = value / maxValue;
        final height = compact
            ? (active ? 22.0 : 14.0)
            : (active ? 38.0 : 24.0 + ratio * 14);
        return Expanded(
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
                  color: active ? color : KarisColors.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: compact ? 5 : 7),
              Text(
                KarisTheme.stageLabels[index],
                style: karisMono(
                  fontSize: compact ? 8 : 9,
                  color: active ? KarisColors.ink : KarisColors.stone,
                  weight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
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
