import 'package:flutter/material.dart';

abstract final class KarisColors {
  static const Color paper = Color(0xFFEEF2EE);
  static const Color surface = Color(0xFFF9FBF7);
  static const Color ink = Color(0xFF202B27);
  static const Color stone = Color(0xFF66716B);
  static const Color jade = Color(0xFF2F6B5C);
  static const Color cinnabar = Color(0xFFC45B43);
  static const Color amber = Color(0xFFB98A2F);
  static const Color hairline = Color(0xFFDCE3DB);
  static const Color jadeSoft = Color(0xFFE7EFE8);
  static const Color amberSoft = Color(0xFFF5EDDA);
  static const Color cinnabarSoft = Color(0xFFF6E7E2);
}

abstract final class KarisTheme {
  static const List<int> stageIntervals = [0, 1, 2, 4, 7, 15, 30, 90, 180];
  static const List<String> stageLabels = [
    '0',
    '1',
    '2',
    '4',
    '7',
    '15',
    '30',
    '90',
    '180',
  ];

  static const String displayFamily = 'Noto Serif SC';
  static const String bodyFamily = 'Noto Sans SC';
  static const String monoFamily = 'IBM Plex Mono';

  static const List<String> bodyFallbacks = [
    'PingFang SC',
    'Microsoft YaHei',
    'sans-serif',
  ];
  static const List<String> displayFallbacks = ['Songti SC', 'STSong', 'serif'];
  static const List<String> monoFallbacks = [
    'SFMono-Regular',
    'Consolas',
    'monospace',
  ];

  static String intervalLabel(int days) {
    if (days <= 0) return '重学';
    if (days == 1) return '1 天';
    return '$days 天';
  }

  static String stageName(int stage) {
    if (stage < 0 || stage >= stageIntervals.length) return 'Stage $stage';
    final days = stageIntervals[stage];
    if (days == 0) return '新卡';
    return '$days 天';
  }
}

ThemeData _buildTheme() {
  final base = Typography.material2021().black;

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: KarisColors.paper,
    colorScheme: const ColorScheme.light(
      primary: KarisColors.jade,
      onPrimary: KarisColors.surface,
      secondary: KarisColors.amber,
      onSecondary: KarisColors.ink,
      error: KarisColors.cinnabar,
      onError: Color(0xFFFFF8F4),
      surface: KarisColors.surface,
      onSurface: KarisColors.ink,
      outline: KarisColors.hairline,
      outlineVariant: KarisColors.hairline,
      surfaceContainerHighest: KarisColors.jadeSoft,
    ),
    fontFamily: KarisTheme.bodyFamily,
    fontFamilyFallback: KarisTheme.bodyFallbacks,
    textTheme: base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontFamily: KarisTheme.displayFamily,
        fontFamilyFallback: KarisTheme.displayFallbacks,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontFamily: KarisTheme.displayFamily,
        fontFamilyFallback: KarisTheme.displayFallbacks,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontFamily: KarisTheme.displayFamily,
        fontFamilyFallback: KarisTheme.displayFallbacks,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontFamily: KarisTheme.displayFamily,
        fontFamilyFallback: KarisTheme.displayFallbacks,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontFamily: KarisTheme.displayFamily,
        fontFamilyFallback: KarisTheme.displayFallbacks,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontFamily: KarisTheme.displayFamily,
        fontFamilyFallback: KarisTheme.displayFallbacks,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 15,
        height: 1.55,
        letterSpacing: 0,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.5,
        letterSpacing: 0,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.45,
        letterSpacing: 0,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      color: KarisColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        side: BorderSide(color: KarisColors.hairline),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: KarisColors.hairline,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: KarisColors.paper,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: KarisColors.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: KarisColors.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: KarisColors.jade, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: KarisColors.cinnabar),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      labelStyle: const TextStyle(color: KarisColors.stone),
      hintStyle: const TextStyle(color: KarisColors.stone),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 46),
        backgroundColor: KarisColors.ink,
        foregroundColor: KarisColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 46),
        foregroundColor: KarisColors.ink,
        side: const BorderSide(color: KarisColors.hairline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: KarisColors.jade,
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: KarisColors.surface,
      elevation: 0,
      contentTextStyle: const TextStyle(
        color: KarisColors.ink,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      behavior: SnackBarBehavior.floating,
      insetPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: KarisColors.hairline),
      ),
    ),
    bannerTheme: MaterialBannerThemeData(
      backgroundColor: KarisColors.surface,
      elevation: 0,
      contentTextStyle: const TextStyle(
        color: KarisColors.ink,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(
        KarisColors.stone.withValues(alpha: 0.45),
      ),
      trackColor: WidgetStatePropertyAll(
        KarisColors.hairline.withValues(alpha: 0.5),
      ),
      thickness: const WidgetStatePropertyAll(6),
      radius: const Radius.circular(3),
      // 卡片很多时 thumb 与内容比例成正比，最小长度兜底，保证可拖拽。
      minThumbLength: 48,
      interactive: true,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: KarisColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: KarisColors.hairline),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: KarisColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
    ),
  );
}

final ThemeData appTheme = _buildTheme();

TextStyle karisMono({
  double fontSize = 12,
  Color color = KarisColors.ink,
  FontWeight weight = FontWeight.w500,
}) {
  return TextStyle(
    fontFamily: KarisTheme.monoFamily,
    fontFamilyFallback: KarisTheme.monoFallbacks,
    fontSize: fontSize,
    color: color,
    fontWeight: weight,
    fontFeatures: const [FontFeature.tabularFigures()],
    letterSpacing: 0,
  );
}

TextStyle karisDisplay({
  double fontSize = 26,
  Color color = KarisColors.ink,
  FontWeight weight = FontWeight.w500,
}) {
  return TextStyle(
    fontFamily: KarisTheme.displayFamily,
    fontFamilyFallback: KarisTheme.displayFallbacks,
    fontSize: fontSize,
    color: color,
    fontWeight: weight,
    height: 1.3,
    letterSpacing: 0,
  );
}
