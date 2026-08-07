import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shared/navigation/tab_navigation.dart';
import '../../shared/widgets/adaptive_scaffold.dart';
import '../../shared/widgets/app_semantics.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/section_widgets.dart';
import '../../shared/widgets/stage_ruler.dart';
import '../../stats/models/stats.dart';
import '../../stats/providers/stats_provider.dart';

import '../../l10n/app_localizations.dart';
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(statsProvider.notifier).loadOverview();
    });
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(statsProvider);
    final authState = ref.watch(authProvider);
    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    final email = authState.user?.email;
    final initial = email == null || email.trim().isEmpty
        ? 'K'
        : email.trim().substring(0, 1).toUpperCase();
    return AdaptiveAppScaffold(
      current: KarisNavItem.home,
      onSelect: (item) => _go(item, context),
      body: RefreshIndicator(
        onRefresh: () async {
          // 下拉刷新是主动行为：强制绕过 5 分钟新鲜度缓存。
          await ref.read(statsProvider.notifier).loadOverview(force: true);
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
                  _HomeHeader(initial: initial),
                  SizedBox(height: 20),
                  _HomeMainColumn(statsAsync: statsAsync),
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

class _HomeHeader extends StatelessWidget {
  final String initial;

  const _HomeHeader({required this.initial});

  /// 首页标题日期格式：DateFormat 构造会初始化 locale 数据，
  /// 首页随统计刷新会重建，复用同一实例避免重复构造。
  static final DateFormat _dateFormat = DateFormat(
    'M月d日 EEEE',
    'zh_CN',
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    final today = _dateFormat.format(DateTime.now());
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Kicker('KARIS REVIEW · 今日'),
              SizedBox(height: 7),
              KarisHeading(
                child: Text(today, style: karisDisplay(fontSize: 27)),
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
          child: Text(
            initial,
            style: TextStyle(
              color: colors.jade,
              fontFamily: KarisTheme.displayFamily,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeMainColumn extends StatelessWidget {
  final AsyncValue<OverviewStats?> statsAsync;

  const _HomeMainColumn({required this.statsAsync});

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
      final l10n = KarisReviewLocalizations.of(context)!;
    final stats = statsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final due = stats?.dueToday ?? 0;
    final reviewed = stats?.reviewedToday ?? 0;
    final newCards = stats?.newCards ?? 0;
    final isLoading = statsAsync.isLoading;
    // 今日任务刻度 = 今日到期分布 + 待学新卡（并入 stage 0，与「待复习/待学习」文案口径一致）。
    // dueStageDistribution 不含未学新卡（next_review_date 为空），直接使用会让 stage 0 恒为 0。
    final distribution = stats == null
        ? List.filled(9, 0)
        : [...stats.dueStageDistribution]..[0] += newCards;

    return KarisEntrance(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(color: colors.hairline),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homeTodayReview,
                        style: TextStyle(
                          color: colors.jade,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(height: 8),
                      if (isLoading)
                        KarisSkeletonGroup(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: KarisSkeleton(
                              width: 104,
                              height: 44,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        )
                      else
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$due',
                                style: karisMono(
                                  fontSize: 54,
                                  weight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: ' 张',
                                style: TextStyle(
                                  color: colors.stone,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 6),
                      if (isLoading)
                        KarisSkeletonGroup(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: KarisSkeleton(
                              width: 150,
                              height: 12,
                            ),
                          ),
                        )
                      else
                        Text(
                          '已复习 $reviewed · 还剩 $due',
                          style: TextStyle(
                            color: colors.stone,
                            fontSize: 12,
                            letterSpacing: 0,
                          ),
                        ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => context.push('/start'),
                  icon: const Icon(Icons.play_arrow_rounded, size: 17),
                  label: const Text('开始'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 18),
          const SectionHeader(title: '记忆刻度', trailing: '0-180 天'),
          SizedBox(height: 14),
          if (isLoading)
            KarisSkeletonGroup(
              child: KarisSkeleton(height: 38, borderRadius: BorderRadius.circular(4)),
            )
          else ...[
            StageRuler(distribution: distribution),
            SizedBox(height: 10),
            Text(
              due > 0
                  ? '$due 张待复习'
                  : newCards > 0
                  ? '$newCards 张待学习'
                  : '今天没有新任务，补充新卡或休息一天',
              style: TextStyle(
                color: colors.stone,
                fontSize: 12,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }

}
