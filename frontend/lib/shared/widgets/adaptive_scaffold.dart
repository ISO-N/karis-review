import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'app_semantics.dart';

enum KarisNavItem { home, decks, stats, settings }

class AdaptiveAppScaffold extends StatefulWidget {
  final Widget body;
  final KarisNavItem current;
  final bool showNavigation;
  final ValueChanged<KarisNavItem>? onSelect;

  const AdaptiveAppScaffold({
    super.key,
    required this.body,
    this.current = KarisNavItem.home,
    this.showNavigation = true,
    this.onSelect,
  });

  @override
  State<AdaptiveAppScaffold> createState() => _AdaptiveAppScaffoldState();
}

class _AdaptiveAppScaffoldState extends State<AdaptiveAppScaffold> {
  final FocusNode _mainFocusNode = FocusNode(debugLabel: '主内容');

  @override
  void dispose() {
    _mainFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;
    return Scaffold(
      backgroundColor: context.karisColors.paper,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              left: 12,
              top: 12,
              child: KarisSkipLink(target: _mainFocusNode),
            ),
            Positioned.fill(
              child: Focus(focusNode: _mainFocusNode, child: widget.body),
            ),
            if (widget.showNavigation) ...[
              _buildNavigationGlass(context, isTablet),
              _buildNavigation(context, isTablet),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationGlass(BuildContext context, bool isTablet) {
    // 全宽条带只做渐变遮罩（无模糊），避免整页出现磨砂分层感；
    // 模糊仅保留在悬浮药丸内部（_buildNavigation）。
    return Positioned(
      left: 0,
      right: 0,
      top: isTablet ? 0 : null,
      bottom: isTablet ? null : 0,
      height: isTablet ? 106 : 78,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: isTablet
                    ? Alignment.topCenter
                    : Alignment.bottomCenter,
                end: isTablet ? Alignment.bottomCenter : Alignment.topCenter,
                colors: [
                  context.karisColors.paper.withValues(alpha: 0.92),
                  context.karisColors.paper.withValues(alpha: 0.72),
                  context.karisColors.paper.withValues(alpha: 0),
                ],
                stops: const [0, 0.6, 1],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigation(BuildContext context, bool isTablet) {
    final colors = context.karisColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final navWidth = isTablet
        ? (width - 64).clamp(0.0, 560.0).toDouble()
        : (width - 36).clamp(0.0, 356.0).toDouble();

    final items = [
      (KarisNavItem.home, Icons.home_outlined, Icons.home, '今日'),
      (KarisNavItem.decks, Icons.layers_outlined, Icons.layers, '卡组'),
      (KarisNavItem.stats, Icons.bar_chart_outlined, Icons.bar_chart, '统计'),
      (KarisNavItem.settings, Icons.settings_outlined, Icons.settings, '设置'),
    ];

    return Positioned(
      left: 0,
      right: 0,
      top: isTablet ? 42 : null,
      bottom: isTablet ? null : 14,
      child: Align(
        alignment: isTablet ? Alignment.topCenter : Alignment.bottomCenter,
        child: Container(
          width: navWidth,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: (isDark ? const Color(0xFF000000) : const Color(0xFF161F1B))
                    .withValues(alpha: isDark ? 0.45 : 0.10),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.78),
                  ),
                ),
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: const Alignment(0, 0.12),
                    colors: [
                      Colors.white.withValues(alpha: isDark ? 0.06 : 0.30),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: Row(
                  children: items.map((item) {
                    final active = item.$1 == widget.current;
                    final color = active ? colors.ink : colors.stone;
                    return Expanded(
                      child: Semantics(
                        selected: active,
                        button: true,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: widget.onSelect == null
                              ? null
                              : () => widget.onSelect!(item.$1),
                          child: Container(
                            decoration: isTablet && active
                                ? BoxDecoration(
                                    color: colors.jade.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  )
                                : null,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!isTablet && active)
                                  Container(
                                    width: 24,
                                    height: 2,
                                    margin: const EdgeInsets.only(bottom: 4),
                                    decoration: BoxDecoration(
                                      color: colors.jade,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                Icon(
                                  active ? item.$3 : item.$2,
                                  size: 20,
                                  color: active ? colors.jade : color,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.$4,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class KarisIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  const KarisIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: color ?? colors.ink),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        minimumSize: const Size(40, 40),
        backgroundColor: colors.surface,
        side: BorderSide(color: colors.hairline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class KarisPrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool expanded;
  final Color? backgroundColor;

  const KarisPrimaryButton({
    super.key,
    required this.label,
    this.icon = Icons.play_arrow_rounded,
    this.onPressed,
    this.expanded = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor ?? colors.ink,
        foregroundColor: colors.surface,
        minimumSize: Size(expanded ? double.infinity : 0, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class KarisSecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expanded;

  const KarisSecondaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon!, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(expanded ? double.infinity : 0, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
