import 'package:flutter/material.dart';

import '../../app/theme.dart';

enum KarisFeedbackTone {
  success(KarisColors.jade, KarisColors.jadeSoft, Icons.check),
  warning(KarisColors.amber, KarisColors.amberSoft, Icons.cloud_off_outlined),
  error(KarisColors.cinnabar, KarisColors.cinnabarSoft, Icons.error_outline);

  const KarisFeedbackTone(this.color, this.softColor, this.icon);

  final Color color;
  final Color softColor;
  final IconData icon;
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
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: tone.softColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(tone.icon, size: 16, color: tone.color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: KarisColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              if (detail != null) ...[
                const SizedBox(height: 2),
                Text(
                  detail!,
                  style: karisMono(fontSize: 10, color: KarisColors.stone),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

SnackBar karisFeedbackSnackBar({
  required KarisFeedbackTone tone,
  required String title,
  String? detail,
  Duration duration = const Duration(milliseconds: 1800),
  EdgeInsetsGeometry? margin,
}) {
  return SnackBar(
    backgroundColor: KarisColors.surface,
    elevation: 0,
    behavior: SnackBarBehavior.floating,
    duration: duration,
    margin: margin,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: KarisColors.hairline),
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
        tone: tone,
        title: title,
        detail: detail,
        duration: duration,
        margin: margin,
      ),
    );
}
