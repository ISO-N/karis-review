import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../utils/motion.dart';
import 'app_semantics.dart';
import 'entrance.dart';

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
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: colors.jadeSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: colors.jade, size: 26),
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
