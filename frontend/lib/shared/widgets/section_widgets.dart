import 'package:flutter/material.dart';

import '../../app/theme.dart';

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
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: KarisColors.ink,
              letterSpacing: 0,
            ),
          ),
        ),
        if (trailing case final value?)
          Text(value, style: karisMono(fontSize: 10, color: KarisColors.stone)),
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
        color: KarisColors.jade,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: KarisColors.jadeSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: KarisColors.jade, size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: karisDisplay(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: KarisColors.stone,
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
    );
  }
}
