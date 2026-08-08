import 'package:flutter/material.dart';

/// Karis Review 语义化颜色 tokens。
///
/// 通过 [ThemeExtension] 挂载到 [ThemeData.extensions]，
/// 页面使用 `context.karisColors.xxx` 访问（见 [KarisColorsContext]），
/// 跟随明暗主题自动切换。禁止在页面中直接引用亮色常量。
@immutable
class KarisColors extends ThemeExtension<KarisColors> {
  /// 页面背景（雾纸 / 夜纸）
  final Color paper;

  /// 卡片、面板、输入框表面（纸面 / 夜面）
  final Color surface;

  /// 主文字、主按钮（墨 / 夜墨）
  final Color ink;

  /// 次级文字、说明（石 / 夜石）
  final Color stone;

  /// 熟悉、完成、主强调（青 / 夜青）
  final Color jade;

  /// 忘记、危险操作；印章确认（第二合法语义：完成页「今日毕」落戳）
  /// （朱 / 夜朱）
  final Color cinnabar;

  /// 模糊、重学（金 / 夜金）
  final Color amber;

  /// 边框、分隔线（发丝线 / 夜线）
  final Color hairline;

  /// jade 弱化底色
  final Color jadeSoft;

  /// amber 弱化底色
  final Color amberSoft;

  /// cinnabar 弱化底色
  final Color cinnabarSoft;

  const KarisColors({
    required this.paper,
    required this.surface,
    required this.ink,
    required this.stone,
    required this.jade,
    required this.cinnabar,
    required this.amber,
    required this.hairline,
    required this.jadeSoft,
    required this.amberSoft,
    required this.cinnabarSoft,
  });

  /// 亮色（现状保持不变）。
  static const KarisColors light = KarisColors(
    paper: Color(0xFFEEF2EE),
    surface: Color(0xFFF9FBF7),
    ink: Color(0xFF202B27),
    stone: Color(0xFF66716B),
    jade: Color(0xFF2F6B5C),
    cinnabar: Color(0xFFC45B43),
    amber: Color(0xFFB98A2F),
    hairline: Color(0xFFDCE3DB),
    jadeSoft: Color(0xFFE7EFE8),
    amberSoft: Color(0xFFF5EDDA),
    cinnabarSoft: Color(0xFFF6E7E2),
  );

  /// 暗色（纸感暗色，非纯黑；语义色提亮一档保证暗底对比度）。
  static const KarisColors dark = KarisColors(
    paper: Color(0xFF131A16),
    surface: Color(0xFF1B231E),
    ink: Color(0xFFE8EFE9),
    stone: Color(0xFF96A49B),
    jade: Color(0xFF57A08B),
    cinnabar: Color(0xFFD9826B),
    amber: Color(0xFFD6AC56),
    hairline: Color(0xFF2C3A32),
    jadeSoft: Color(0xFF22312A),
    amberSoft: Color(0xFF332B1C),
    cinnabarSoft: Color(0xFF362220),
  );

  @override
  KarisColors copyWith({
    Color? paper,
    Color? surface,
    Color? ink,
    Color? stone,
    Color? jade,
    Color? cinnabar,
    Color? amber,
    Color? hairline,
    Color? jadeSoft,
    Color? amberSoft,
    Color? cinnabarSoft,
  }) {
    return KarisColors(
      paper: paper ?? this.paper,
      surface: surface ?? this.surface,
      ink: ink ?? this.ink,
      stone: stone ?? this.stone,
      jade: jade ?? this.jade,
      cinnabar: cinnabar ?? this.cinnabar,
      amber: amber ?? this.amber,
      hairline: hairline ?? this.hairline,
      jadeSoft: jadeSoft ?? this.jadeSoft,
      amberSoft: amberSoft ?? this.amberSoft,
      cinnabarSoft: cinnabarSoft ?? this.cinnabarSoft,
    );
  }

  @override
  KarisColors lerp(ThemeExtension<KarisColors>? other, double t) {
    if (other is! KarisColors) return this;
    return KarisColors(
      paper: Color.lerp(paper, other.paper, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      stone: Color.lerp(stone, other.stone, t)!,
      jade: Color.lerp(jade, other.jade, t)!,
      cinnabar: Color.lerp(cinnabar, other.cinnabar, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      jadeSoft: Color.lerp(jadeSoft, other.jadeSoft, t)!,
      amberSoft: Color.lerp(amberSoft, other.amberSoft, t)!,
      cinnabarSoft: Color.lerp(cinnabarSoft, other.cinnabarSoft, t)!,
    );
  }
}

/// 便捷访问：`context.karisColors.jade`。
extension KarisColorsContext on BuildContext {
  KarisColors get karisColors =>
      Theme.of(this).extension<KarisColors>() ?? KarisColors.light;
}

abstract final class KarisTheme {
  /// 语义化间距刻度（像素）。页面/组件统一取此常量，避免硬编码散值。
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 20;
  static const double space2xl = 24;
  static const double space3xl = 32;
  static const double space4xl = 40;
  static const double space5xl = 48;

  /// 语义化圆角刻度（像素）。与全局卡片/输入框圆角保持一致。
  static const double radiusSm = 8;
  static const double radiusMd = 10;
  static const double radiusLg = 12;
  static const double radiusPill = 32;

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

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final c = isDark ? KarisColors.dark : KarisColors.light;
  final base =
      isDark ? Typography.material2021().white : Typography.material2021().black;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: c.paper,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: c.jade,
      onPrimary: isDark ? const Color(0xFF07130F) : c.surface,
      secondary: c.amber,
      onSecondary: isDark ? const Color(0xFF251A03) : c.ink,
      error: c.cinnabar,
      onError: isDark ? const Color(0xFF240B06) : const Color(0xFFFFF8F4),
      surface: c.surface,
      onSurface: c.ink,
      outline: c.hairline,
      outlineVariant: c.hairline,
      surfaceContainerHighest: c.jadeSoft,
    ),
    fontFamily: KarisTheme.bodyFamily,
    fontFamilyFallback: KarisTheme.bodyFallbacks,
    // 焦点/悬停 overlay 基色：语义 jade，确保键盘聚焦可见（WCAG 焦点可达）。
    focusColor: c.jade.withValues(alpha: 0.14),
    hoverColor: c.jade.withValues(alpha: 0.08),
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
    cardTheme: CardThemeData(
      elevation: 0,
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(KarisTheme.radiusSm)),
        side: BorderSide(color: c.hairline),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: c.hairline,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.paper,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c.jade, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c.cinnabar),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      labelStyle: TextStyle(color: c.stone),
      hintStyle: TextStyle(color: c.stone),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 46)),
        backgroundColor: WidgetStatePropertyAll(c.jade),
        foregroundColor: WidgetStatePropertyAll(c.surface),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return c.surface.withValues(alpha: 0.16);
          }
          if (states.contains(WidgetState.focused)) {
            return c.surface.withValues(alpha: 0.12);
          }
          return c.surface.withValues(alpha: 0.10);
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KarisTheme.radiusSm),
          ),
        ),
        textStyle: const WidgetStatePropertyAll(TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        )),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 46)),
        foregroundColor: WidgetStatePropertyAll(c.ink),
        side: WidgetStatePropertyAll(BorderSide(color: c.hairline)),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return c.jade.withValues(alpha: 0.10);
          }
          return c.jade.withValues(alpha: 0.06);
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KarisTheme.radiusSm),
          ),
        ),
        textStyle: const WidgetStatePropertyAll(TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        )),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(c.jade),
        minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return c.jade.withValues(alpha: 0.14);
          }
          return c.jade.withValues(alpha: 0.08);
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KarisTheme.radiusSm),
          ),
        ),
        textStyle: const WidgetStatePropertyAll(TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        )),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.surface,
      elevation: 0,
      contentTextStyle: TextStyle(
        color: c.ink,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      behavior: SnackBarBehavior.floating,
      insetPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: c.hairline),
      ),
    ),
    bannerTheme: MaterialBannerThemeData(
      backgroundColor: c.surface,
      elevation: 0,
      contentTextStyle: TextStyle(
        color: c.ink,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(
        c.stone.withValues(alpha: 0.45),
      ),
      trackColor: WidgetStatePropertyAll(
        c.hairline.withValues(alpha: 0.5),
      ),
      thickness: const WidgetStatePropertyAll(6),
      radius: const Radius.circular(3),
      // 卡片很多时 thumb 与内容比例成正比，最小长度兜底，保证可拖拽。
      minThumbLength: 48,
      interactive: true,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KarisTheme.radiusMd),
        side: BorderSide(color: c.hairline),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(KarisTheme.radiusMd),
        ),
      ),
    ),
    extensions: [c],
  );
}

final ThemeData appTheme = _buildTheme(Brightness.light);

final ThemeData appDarkTheme = _buildTheme(Brightness.dark);

TextStyle karisMono({
  double fontSize = 12,
  Color? color,
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
  Color? color,
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

/// 纪念碑场景大数字（衬线渲染）。
///
/// 与等宽数字的分工规则：
/// - [karisMono]（等宽）用于需要对齐的数据场景——统计数字、进度、快捷键；
/// - [karisMonument]（衬线）用于「值得被记住」的大数字——今日待办、已掌握数，
///   让数字像碑文一样立起来。两条规则不要混用，混用会破坏数字的节奏感。
TextStyle karisMonument({
  double fontSize = 54,
  Color? color,
  FontWeight weight = FontWeight.w500,
}) {
  return TextStyle(
    fontFamily: KarisTheme.displayFamily,
    fontFamilyFallback: KarisTheme.displayFallbacks,
    fontSize: fontSize,
    color: color,
    fontWeight: weight,
    height: 1.12,
    letterSpacing: 0,
  );
}
