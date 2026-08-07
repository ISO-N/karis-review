import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../shared/navigation/tab_navigation.dart';
import '../../shared/utils/motion.dart';
import '../../shared/widgets/adaptive_scaffold.dart';
import '../../shared/widgets/app_semantics.dart';
import '../../shared/widgets/loading_widget.dart';
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
      // loadOverview 内置 5 分钟新鲜度缓存：命中时返回 false 不触发网络同步，
      // 因此只在真正刷新成功后才联动刷新趋势图，避免每次进入都闪加载。
      ref.read(statsProvider.notifier).loadOverview().then((refreshed) {
        if (refreshed) {
          ref.invalidate(trendProvider(30));
        }
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
          // 下拉刷新是用户主动行为：强制绕过缓存并刷新趋势图。
          await ref.read(statsProvider.notifier).loadOverview(force: true);
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
                      child: LoadingWidget(),
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
    goToTab(context, ref, item);
  }
}

class _StatsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
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
            color: colors.surface,
            border: Border.all(color: colors.hairline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.bar_chart, size: 18, color: colors.jade),
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
    final colors = context.karisColors;
    final metrics = [
      MetricTile(
        label: '总卡片',
        value: '${stats.totalCards}',
        icon: Icons.credit_card_outlined,
      ),
      MetricTile(
        label: '卡组',
        value: '${stats.totalDecks}',
        icon: Icons.layers_outlined,
      ),
      MetricTile(
        label: '待复习',
        value: '${stats.dueToday}',
        valueColor: colors.cinnabar,
        icon: Icons.schedule_outlined,
      ),
      MetricTile(
        label: '今日复习',
        value: '${stats.reviewedToday}',
        valueColor: colors.jade,
        icon: Icons.check_circle_outline,
      ),
      MetricTile(
        label: '今日新学',
        value: '${stats.learnedToday}',
        valueColor: colors.jade,
        icon: Icons.auto_stories_outlined,
      ),
      MetricTile(
        label: '已掌握',
        value: '${stats.masteredCards}',
        valueColor: colors.jade,
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
          // 趋势图被 invalidate 后台刷新时，保留上一次渲染的旧图表，
          // 新数据就绪后再平滑替换，避免进入页面闪加载。
          skipLoadingOnRefresh: true,
          loading: () => const SizedBox(
            height: 180,
            child: LoadingWidget(),
          ),
          error: (error, _) => SizedBox(
            height: 140,
            child: Center(
              child: Text(
                '趋势加载失败',
                style: TextStyle(color: context.karisColors.cinnabar),
              ),
            ),
          ),
          data: (trend) {
            if (trend.isEmpty) {
              return SizedBox(
                height: 140,
                child: Center(
                  child: Text(
                    '暂无趋势数据',
                    style: TextStyle(color: context.karisColors.stone),
                  ),
                ),
              );
            }
            return AspectRatio(
              aspectRatio: 3.2,
              child: _TrendChart(points: trend),
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
    final colors = context.karisColors;
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
                      duration: reducedDuration(context, KarisMotion.grow),
                      curve: KarisMotion.easeOut,
                      height: height,
                      decoration: BoxDecoration(
                        color: colors.jade,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      KarisTheme.stageLabels[index],
                      style: karisMono(fontSize: 8, color: colors.stone),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '阶段越高，复习间隔越长。已掌握卡片集中在 15 天以上。',
          style: TextStyle(
            color: colors.stone,
            fontSize: 12,
            height: 1.6,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

/// 趋势图轴标签 / tooltip 共用的日期格式。
/// DateFormat 构造会初始化 locale 数据，painter 每次 paint 新建成本高，
/// 提为顶层 final 复用（同一格式单线程使用，无并发问题）。
final DateFormat _trendDateFormat = DateFormat('M/d');

/// 趋势图：600ms 从左到右生长 + 点击数据点显示 tooltip。
class _TrendChart extends StatefulWidget {
  final List<TrendPoint> points;

  const _TrendChart({required this.points});

  @override
  State<_TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<_TrendChart> {
  int? _hoverIndex;

  int _indexAt(double dx, double width) {
    if (widget.points.length <= 1) return 0;
    const left = 8.0;
    const right = 8.0;
    final chartWidth = width - left - right;
    final stepX = chartWidth / (widget.points.length - 1);
    return ((dx - left) / stepX).round().clamp(0, widget.points.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final hover = _hoverIndex;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final index = _indexAt(details.localPosition.dx, width);
            if (hover != index) setState(() => _hoverIndex = index);
          },
          onTapCancel: () => setState(() => _hoverIndex = null),
          child: Stack(
            children: [
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: reducedDuration(context, KarisMotion.grow),
                  curve: KarisMotion.easeOut,
                  builder: (context, progress, _) => CustomPaint(
                    painter: TrendChartPainter(
                      points: widget.points,
                      colors: context.karisColors,
                      progress: progress,
                    ),
                  ),
                ),
              ),
              if (hover != null) _buildTooltip(context, hover, width),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTooltip(BuildContext context, int index, double chartWidth) {
    final colors = context.karisColors;
    final point = widget.points[index];
    final parsed = DateTime.tryParse(point.date);
    final label = parsed != null ? _trendDateFormat.format(parsed) : point.date;
    const tooltipWidth = 76.0;
    final x = _indexX(index, chartWidth);
    return Positioned(
      left: (x - tooltipWidth / 2).clamp(0.0, chartWidth - tooltipWidth),
      top: 4,
      child: IgnorePointer(
        child: Container(
          width: tooltipWidth,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.hairline),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF161F1B).withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: karisMono(fontSize: 9, color: colors.stone)),
              const SizedBox(height: 2),
              Text(
                '${point.reviewed} 次',
                style: karisMono(
                  fontSize: 11,
                  color: colors.jade,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 与 TrendChartPainter 一致的 x 坐标（图表宽度按父级布局推算）。
  double _indexX(int index, double width) {
    if (widget.points.length <= 1) return width / 2;
    const left = 8.0;
    const right = 8.0;
    final chartWidth = width - left - right;
    final stepX = chartWidth / (widget.points.length - 1);
    return left + stepX * index;
  }
}

class TrendChartPainter extends CustomPainter {
  final List<TrendPoint> points;

  /// 生长进度 0..1：控制从左到右揭示的可见宽度。
  final double progress;

  final KarisColors colors;

  TrendChartPainter({
    required this.points,
    required this.colors,
    this.progress = 1,
  });

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
      final y = baselineY - (points[index].reviewed / maxY) * chartHeight;
      return Offset(x, y);
    }

    // 生长动画：裁剪到可见宽度，让线条/面积/数据点从左到右自然揭示。
    final visibleRight = left + chartWidth * progress.clamp(0.0, 1.0);
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(0, 0, visibleRight + 2, size.height),
    );

    final axisPaint = Paint()
      ..color = colors.hairline
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
      ..color = colors.jade.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = colors.jade
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(areaPath, areaPaint);
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()
      ..color = colors.surface
      ..strokeWidth = 1.6
      ..style = PaintingStyle.fill;
    final dotBorder = Paint()
      ..color = colors.jade
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final step = math.max(1, (points.length / 5).floor());
    for (var i = 0; i < points.length; i += step) {
      final offset = pointAt(i);
      canvas.drawCircle(offset, 3, dotBorder);
      canvas.drawCircle(offset, 3, dotPaint);
    }

    canvas.restore();

    final labelStyle = karisMono(fontSize: 9, color: colors.stone);
    for (var i = 0; i < points.length; i += step) {
      final offset = pointAt(i);
      final parsed = DateTime.tryParse(points[i].date);
      final text = parsed != null ? _trendDateFormat.format(parsed) : points[i].date;
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
    return oldDelegate.points != points ||
        oldDelegate.progress != progress ||
        oldDelegate.colors != colors;
  }
}
