import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../utils/motion.dart';
import 'app_semantics.dart';
import 'entrance.dart';
import 'memory_ring.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final Widget? action;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    return Row(
      children: [
        Expanded(
          child: KarisHeading(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.ink,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
        if (trailing case final value?)
          Text(value, style: karisMono(fontSize: 10, color: colors.stone)),
        ?action,
      ],
    );
  }
}

class Kicker extends StatelessWidget {
  final String text;

  const Kicker(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: karisMono(
        fontSize: 11,
        color: context.karisColors.jade,
        weight: FontWeight.w500,
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: KarisEntrance(
          duration: KarisMotion.grow,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 空刻度环：progress=0 的记忆刻度环只留下底环与刻度——
              // 「环还在，等待第一圈」。与今日页年轮、完成页收满环同源，
              // 让空状态也从「图标方块」升维为母题落点。
              // 装饰性元素：排除语义，避免屏幕阅读器重复朗读图形本身。
              ExcludeSemantics(
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: MemoryRing(
                          progress: 0,
                          size: 58,
                          strokeWidth: 2.5,
                          tickLength: 3,
                          tickCount: 24,
                        ),
                      ),
                      Icon(icon, color: colors.jade, size: 22),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              KarisHeading(
                child: Text(
                  title,
                  style: karisDisplay(fontSize: 20, color: colors.ink),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  color: colors.stone,
                  fontSize: 13,
                  height: 1.6,
                  letterSpacing: 0,
                ),
                textAlign: TextAlign.center,
              ),
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      ),
    );
  }
}
