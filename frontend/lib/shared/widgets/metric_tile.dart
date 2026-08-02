import 'package:flutter/material.dart';

import '../../app/theme.dart';

class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData? icon;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = KarisColors.ink,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: KarisColors.surface,
          border: Border.all(color: KarisColors.hairline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: valueColor),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: KarisColors.stone,
                        fontSize: 12,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              value,
              style: karisMono(
                fontSize: 26,
                color: valueColor,
                weight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
