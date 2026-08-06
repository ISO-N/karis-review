import 'package:flutter/material.dart';

import '../../app/theme.dart';

enum KarisFeedbackTone { success, warning, error }

extension KarisFeedbackToneStyle on KarisFeedbackTone {
  Color color(KarisColors c) => switch (this) {
        KarisFeedbackTone.success => c.jade,
        KarisFeedbackTone.warning => c.amber,
        KarisFeedbackTone.error => c.cinnabar,
      };

  Color softColor(KarisColors c) => switch (this) {
        KarisFeedbackTone.success => c.jadeSoft,
        KarisFeedbackTone.warning => c.amberSoft,
        KarisFeedbackTone.error => c.cinnabarSoft,
      };

  IconData get icon => switch (this) {
        KarisFeedbackTone.success => Icons.check,
        KarisFeedbackTone.warning => Icons.cloud_off_outlined,
        KarisFeedbackTone.error => Icons.error_outline,
      };
}

class KarisFeedbackBar extends StatelessWidget {
  const KarisFeedbackBar({
    super.key,
    required this.tone,
    required this.title,
    this.detail,
  });

  final KarisFeedbackTone tone;
  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: tone.softColor(colors),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(tone.icon, size: 16, color: tone.color(colors)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              if (detail != null) ...[
                const SizedBox(height: 2),
                Text(
                  detail!,
                  style: karisMono(fontSize: 10, color: colors.stone),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

SnackBar karisFeedbackSnackBar(
  BuildContext context, {
  required KarisFeedbackTone tone,
  required String title,
  String? detail,
  Duration duration = const Duration(milliseconds: 1800),
  EdgeInsetsGeometry? margin,
}) {
  final colors = context.karisColors;
  return SnackBar(
    backgroundColor: colors.surface,
    elevation: 0,
    behavior: SnackBarBehavior.floating,
    duration: duration,
    margin: margin,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: colors.hairline),
    ),
    content: KarisFeedbackBar(tone: tone, title: title, detail: detail),
  );
}

void showKarisFeedback(
  BuildContext context, {
  required KarisFeedbackTone tone,
  required String title,
  String? detail,
  Duration duration = const Duration(milliseconds: 1800),
  EdgeInsetsGeometry? margin,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      karisFeedbackSnackBar(
        context,
        tone: tone,
        title: title,
        detail: detail,
        duration: duration,
        margin: margin,
      ),
    );
}
