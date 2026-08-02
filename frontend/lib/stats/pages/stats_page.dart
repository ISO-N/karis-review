import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../shared/utils/motion.dart';
import '../../shared/widgets/adaptive_scaffold.dart';
import '../../shared/widgets/app_semantics.dart';
import '../../shared/widgets/metric_tile.dart';
import '../../shared/widgets/section_widgets.dart';
import '../models/stats.dart';
import '../providers/stats_provider.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(statsProvider.notifier).loadOverview().then((_) {
        ref.invalidate(trendProvider(30));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(statsProvider);
    final trendAsync = ref.watch(trendProvider(30));
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    return AdaptiveAppScaffold(
      current: KarisNavItem.stats,
      onSelect: (item) => _go(item, context),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([ref.read(statsProvider.notifier).loadOverview()]);
          ref.invalidate(trendProvider(30));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20,
            isTablet ? 132 : 20,
            20,
            isTablet ? 24 : 132,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatsHeader(),
                  const SizedBox(height: 20),
                  statsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (error, _) => EmptyState(
                      icon: Icons.error_outline,
                      title: '统计加载失败',
                      message: '统计加载失败，请检查网络后重试',
                      action: TextButton(
                        onPressed: () =>
                            ref.read(statsProvider.notifier).loadOverview(),
                        child: const Text('重试'),
                      ),
                    ),
                    data: (value) {
                      if (value == null) {
                        return const EmptyState(
                          icon: Icons.bar_chart_outlined,
                          title: '暂无统计数据',
                          message: '开始复习后会在这里出现趋势',
                        );
                      }
                      final main = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MetricGrid(stats: value),
                          const SizedBox(height: 20),
                          _TrendPanel(trendAsync: trendAsync),
                        ],
                      );
                      final side = _DistributionPanel(stats: value);
                      if (!isTablet) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [main, const SizedBox(height: 24), side],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 12, child: main),
                          const SizedBox(width: 28),
                          Expanded(flex: 8, child: side),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _go(KarisNavItem item, BuildContext context) {
    switch (item) {
      case KarisNavItem.home:
        context.go('/home');
      case KarisNavItem.decks:
        context.go('/decks');
      case KarisNavItem.stats:
        context.go('/stats');
      case KarisNavItem.settings:
        context.go('/settings');
    }
  }
}

class _StatsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Kicker('PROGRESS'),
              const SizedBox(height: 7),
              KarisHeading(
                child: Text('学习统计', style: karisDisplay(fontSize: 27)),
              ),
            ],
          ),
        ),
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: KarisColors.surface,
            border: Border.all(color: KarisColors.hairline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.bar_chart, size: 18, color: KarisColors.jade),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final OverviewStats stats;

  const _MetricGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final metrics = [
      MetricTile(
        label: '总卡片',
        value: '${stats.totalCards}',
        icon: Icons.credit_card_outlined,
      ),
      MetricTile(
        label: '牌组',
        value: '${stats.totalDecks}',
        icon: Icons.layers_outlined,
      ),
      MetricTile(
        label: '待复习',
        value: '${stats.dueToday}',
        valueColor: KarisColors.cinnabar,
        icon: Icons.schedule_outlined,
      ),
      MetricTile(
        label: '今日复习',
        value: '${stats.reviewedToday}',
        valueColor: KarisColors.jade,
        icon: Icons.check_circle_outline,
      ),
      MetricTile(
        label: '今日新学',
        value: '${stats.learnedToday}',
        valueColor: KarisColors.jade,
        icon: Icons.auto_stories_outlined,
      ),
      MetricTile(
        label: '已掌握',
        value: '${stats.masteredCards}',
        valueColor: KarisColors.jade,
        icon: Icons.done_all_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 3 : 2;
        final spacing = 10.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final metric in metrics)
              SizedBox(width: itemWidth, child: metric),
          ],
        );
      },
    );
  }
}

class _TrendPanel extends StatelessWidget {
  final AsyncValue<List<TrendPoint>> trendAsync;

  const _TrendPanel({required this.trendAsync});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '复习趋势', trailing: '最近 30 天'),
        const SizedBox(height: 12),
        trendAsync.when(
          loading: () => const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (error, _) => const SizedBox(
            height: 140,
            child: Center(
              child: Text(
                '趋势加载失败',
                style: TextStyle(color: KarisColors.cinnabar),
              ),
            ),
          ),
          data: (trend) {
            if (trend.isEmpty) {
              return const SizedBox(
                height: 140,
                child: Center(
                  child: Text(
                    '暂无趋势数据',
                    style: TextStyle(color: KarisColors.stone),
                  ),
                ),
              );
            }
            return AspectRatio(
              aspectRatio: 3.2,
              child: CustomPaint(painter: TrendChartPainter(points: trend)),
            );
          },
        ),
      ],
    );
  }
}

class _DistributionPanel extends StatelessWidget {
  final OverviewStats stats;

  const _DistributionPanel({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: '阶段分布', trailing: '${stats.masteredCards} 已掌握'),
        const SizedBox(height: 16),
        SizedBox(
          height: 132,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(9, (index) {
              final value = index < stats.stageDistribution.length
                  ? stats.stageDistribution[index]
                  : 0;
              final max = stats.stageDistribution.fold<int>(
                1,
                (current, item) => item > current ? item : current,
              );
              final height = max == 0 ? 4.0 : 4.0 + (value / max) * 104;
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedContainer(
                      duration: reducedDuration(
                        context,
                        const Duration(milliseconds: 450),
                      ),
                      curve: Curves.easeOutCubic,
                      height: height,
                      decoration: const BoxDecoration(
                        color: KarisColors.jade,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      KarisTheme.stageLabels[index],
                      style: karisMono(fontSize: 8, color: KarisColors.stone),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '阶段越高，复习间隔越长。已掌握卡片集中在 15 天以上。',
          style: TextStyle(
            color: KarisColors.stone,
            fontSize: 12,
            height: 1.6,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class TrendChartPainter extends CustomPainter {
  final List<TrendPoint> points;

  TrendChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final maxY = points.fold<int>(
      5,
      (current, point) => point.reviewed > current ? point.reviewed : current,
    );
    final left = 8.0;
    final right = 8.0;
    final top = 18.0;
    final bottom = 24.0;
    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;
    final baselineY = top + chartHeight;
    final stepX = points.length == 1 ? 0.0 : chartWidth / (points.length - 1);

    Offset pointAt(int index) {
      final x = left + stepX * index;
      final y =
          baselineY - (points[index].reviewed / maxY) * chartHeight;
      return Offset(x, y);
    }

    final axisPaint = Paint()
      ..color = KarisColors.hairline
      ..strokeWidth = 1;
    canvas.drawLine(Offset(left, top), Offset(left, baselineY), axisPaint);
    canvas.drawLine(
      Offset(left, baselineY),
      Offset(left + chartWidth, baselineY),
      axisPaint,
    );

    final linePath = Path();
    final areaPath = Path();
    for (var i = 0; i < points.length; i++) {
      final offset = pointAt(i);
      if (i == 0) {
        linePath.moveTo(offset.dx, offset.dy);
        areaPath.moveTo(offset.dx, baselineY);
        areaPath.lineTo(offset.dx, offset.dy);
      } else {
        linePath.lineTo(offset.dx, offset.dy);
        areaPath.lineTo(offset.dx, offset.dy);
      }
    }
    areaPath.lineTo(left + chartWidth, baselineY);
    areaPath.close();

    final areaPaint = Paint()
      ..color = KarisColors.jade.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = KarisColors.jade
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(areaPath, areaPaint);
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()
      ..color = KarisColors.surface
      ..strokeWidth = 1.6
      ..style = PaintingStyle.fill;
    final dotBorder = Paint()
      ..color = KarisColors.jade
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final step = math.max(1, (points.length / 5).floor());
    for (var i = 0; i < points.length; i += step) {
      final offset = pointAt(i);
      canvas.drawCircle(offset, 3, dotBorder);
      canvas.drawCircle(offset, 3, dotPaint);
    }

    final labelStyle = karisMono(fontSize: 9, color: KarisColors.stone);
    final dateFormat = DateFormat('M/d');
    for (var i = 0; i < points.length; i += step) {
      final offset = pointAt(i);
      final parsed = DateTime.tryParse(points[i].date);
      final text = parsed != null ? dateFormat.format(parsed) : points[i].date;
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(
          (offset.dx - textPainter.width / 2)
              .clamp(0, size.width - textPainter.width)
              .toDouble(),
          size.height - 16,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant TrendChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
