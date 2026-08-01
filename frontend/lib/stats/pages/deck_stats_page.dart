import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_widget.dart';
import '../providers/deck_stats_provider.dart';


class DeckStatsPage extends ConsumerWidget {
  final String deckId;

  const DeckStatsPage({super.key, required this.deckId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(deckStatsProvider(deckId));

    return Scaffold(
      appBar: AppBar(title: const Text('牌组进度')),
      body: statsAsync.when(
        loading: () => const LoadingWidget(message: '加载牌组统计中...'),
        error: (e, _) => AppErrorWidget(
          message: '加载失败: $e',
          onRetry: () => ref.invalidate(deckStatsProvider(deckId)),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(deckStatsProvider(deckId)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stats.deckName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildMetric(context, '总卡片', '${stats.totalCards}', Icons.credit_card, Colors.blue),
                    const SizedBox(width: 12),
                    _buildMetric(context, '待复习', '${stats.dueToday}', Icons.replay, Colors.orange),
                    const SizedBox(width: 12),
                    _buildMetric(context, '今日已复习', '${stats.reviewedToday}', Icons.check_circle, Colors.green),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('阶段分布',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildStageChart(context, stats.stageDistribution),
                const SizedBox(height: 16),
                _buildStageLegend(context, stats.stageDistribution),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(BuildContext context, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageChart(BuildContext context, Map<String, int> distribution) {
    final entries = List.generate(9, (i) {
      final count = distribution['$i'] ?? 0;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: Theme.of(context).colorScheme.primary,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                const FlLine(color: Colors.black12, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 32),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('S${value.toInt()}',
                        style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: entries,
        ),
      ),
    );
  }

  Widget _buildStageLegend(BuildContext context, Map<String, int> distribution) {
    const stageNames = ['学习中', '1天', '2天', '4天', '7天', '15天', '30天', '90天', '180天'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(9, (i) {
        final count = distribution['$i'] ?? 0;
        return Chip(
          label: Text('Stage $i · ${stageNames[i]} · $count 张',
              style: const TextStyle(fontSize: 12)),
          backgroundColor: Colors.grey.withValues(alpha: 0.08),
          visualDensity: VisualDensity.compact,
        );
      }),
    );
  }
}