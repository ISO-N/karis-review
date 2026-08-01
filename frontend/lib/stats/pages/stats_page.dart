import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_widget.dart';
import '../providers/stats_provider.dart';
import '../models/stats.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);
    final trendAsync = ref.watch(trendProvider(30));

    return Scaffold(
      appBar: AppBar(title: const Text('学习统计')),
      body: statsAsync.when(
        loading: () => const LoadingWidget(message: '加载统计中...'),
        error: (e, _) => AppErrorWidget(
          message: '加载失败: $e',
          onRetry: () => ref.read(statsProvider.notifier).loadOverview(),
        ),
        data: (stats) {
          if (stats == null) {
            return const Center(child: Text('暂无统计数据'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(statsProvider.notifier).loadOverview(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverviewGrid(context, stats),
                  const SizedBox(height: 24),
                  const Text('复习趋势',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: trendAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('加载趋势失败: $e')),
                      data: (trend) {
                        if (trend.isEmpty) {
                          return const Center(child: Text('暂无趋势数据'));
                        }
                        return _buildTrendChart(context, trend);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.book), label: '牌组'),
          BottomNavigationBarItem(icon: Icon(Icons.replay), label: '复习'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '统计'),
        ],
        onTap: (index) {
          switch (index) {
            case 0: context.go('/decks');
            case 1: context.go('/review');
            case 2: break;
          }
        },
      ),
    );
  }

  Widget _buildOverviewGrid(BuildContext context, OverviewStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('学习概览',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildStatCard(context, '总卡片', '${stats.totalCards}', Icons.credit_card, Colors.blue),
            const SizedBox(width: 12),
            _buildStatCard(context, '牌组', '${stats.totalDecks}', Icons.book, Colors.purple),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard(context, '待复习', '${stats.dueToday}', Icons.replay, Colors.orange),
            const SizedBox(width: 12),
            _buildStatCard(context, '今日复习', '${stats.reviewedToday}', Icons.check_circle, Colors.green),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard(context, '已掌握', '${stats.masteredCards}', Icons.emoji_events, Colors.amber),
            const SizedBox(width: 12),
            _buildStatCard(context, '学习中', '${stats.learningCards}', Icons.trending_up, Colors.teal),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  )),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendChart(BuildContext context, List<TrendPoint> trend) {
    final maxY = trend.fold<int>(0, (max, p) => p.reviewed > max ? p.reviewed : max);
    final maxVal = maxY < 5 ? 5 : maxY;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxVal / 4).ceilToDouble().clamp(1, double.infinity),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (trend.length / 5).ceilToDouble().clamp(1, double.infinity),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= trend.length) return const Text('');
                return Text(trend[index].date.substring(5),
                    style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (trend.length - 1).toDouble(),
        minY: 0,
        maxY: maxVal.toDouble(),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(trend.length, (i) => FlSpot(i.toDouble(), trend[i].reviewed.toDouble())),
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}