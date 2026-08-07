import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../stats/providers/stats_provider.dart';
import '../widgets/adaptive_scaffold.dart';

/// 底部导航跳转（home / decks / stats / settings 四个 tab 页共用）。
///
/// 切换到统计页前先触发一次统计预取（方案 B：导航预取）——
/// 把可能已过期的网络同步提前到「点击 → 转场动画结束」的窗口内完成，
/// 进入统计页时数据往往已经就绪，页面内 initState 的加载请求会因
/// in-flight 防重入 / 5 分钟新鲜度缓存而直接跳过，零重复请求。
///
/// 预取对命中缓存的场景零开销；失败静默忽略（页面内仍有兜底加载）。
void goToTab(
  BuildContext context,
  WidgetRef ref,
  KarisNavItem item,
) {
  if (item == KarisNavItem.stats) {
    ref.read(statsProvider.notifier).loadOverview().then((refreshed) {
      // 仅在实际刷新成功后才联动刷新趋势图；页面若已离开则放弃。
      if (refreshed && context.mounted) {
        ref.invalidate(trendProvider(30));
      }
    });
  }
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
