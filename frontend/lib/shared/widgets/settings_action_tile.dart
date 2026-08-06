import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'app_semantics.dart';

class SettingsActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool danger;
  final Widget? trailing;

  const SettingsActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.danger = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    final color = danger ? colors.cinnabar : colors.jade;
    return KarisInteractive(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 58),
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(
              color: danger
                  ? colors.cinnabar.withValues(alpha: 0.42)
                  : colors.hairline,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: danger ? colors.cinnabarSoft : colors.jadeSoft,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 17, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: danger ? colors.cinnabar : colors.ink,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colors.stone,
                        fontSize: 11,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
