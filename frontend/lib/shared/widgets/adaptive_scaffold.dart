import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme.dart';

enum KarisNavItem { home, decks, stats, settings }

class AdaptiveAppScaffold extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: KarisColors.paper,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: body),
            if (showNavigation) ...[
              _buildNavigationGlass(context, isTablet),
              _buildNavigation(context, isTablet),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationGlass(BuildContext context, bool isTablet) {
    return Positioned(
      left: 0,
      right: 0,
      top: isTablet ? 0 : null,
      bottom: isTablet ? null : 0,
      height: isTablet ? 106 : 78,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: isTablet
                      ? Alignment.topCenter
                      : Alignment.bottomCenter,
                  end: isTablet ? Alignment.bottomCenter : Alignment.topCenter,
                  colors: const [
                    Colors.black,
                    Colors.black,
                    Colors.transparent,
                  ],
                  stops: const [0, 0.6, 1],
                ).createShader(bounds),
                blendMode: BlendMode.dstIn,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: isTablet
                          ? Alignment.topCenter
                          : Alignment.bottomCenter,
                      end: isTablet
                          ? Alignment.bottomCenter
                          : Alignment.topCenter,
                      colors: [
                        KarisColors.surface.withValues(alpha: 0.55),
                        KarisColors.surface.withValues(alpha: 0.24),
                        KarisColors.surface.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigation(BuildContext context, bool isTablet) {
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
                color: const Color(0xFF161F1B).withValues(alpha: 0.10),
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
                  color: KarisColors.surface.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: const Alignment(0, 0.12),
                    colors: [
                      Colors.white.withValues(alpha: 0.30),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: Row(
                  children: items.map((item) {
                    final active = item.$1 == current;
                    final color = active ? KarisColors.ink : KarisColors.stone;
                    return Expanded(
                      child: Semantics(
                        selected: active,
                        button: true,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: onSelect == null
                              ? null
                              : () => onSelect!(item.$1),
                          child: Container(
                            decoration: isTablet && active
                                ? BoxDecoration(
                                    color: KarisColors.jade.withValues(
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
                                      color: KarisColors.jade,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                Icon(
                                  active ? item.$3 : item.$2,
                                  size: 20,
                                  color: active ? KarisColors.jade : color,
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
  final Color color;

  const KarisIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.color = KarisColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: color),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        minimumSize: const Size(40, 40),
        backgroundColor: KarisColors.surface,
        side: const BorderSide(color: KarisColors.hairline),
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
  final Color backgroundColor;

  const KarisPrimaryButton({
    super.key,
    required this.label,
    this.icon = Icons.play_arrow_rounded,
    this.onPressed,
    this.expanded = true,
    this.backgroundColor = KarisColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: KarisColors.surface,
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
