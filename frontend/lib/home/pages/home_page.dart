import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../deck/models/deck.dart';
import '../../deck/providers/deck_provider.dart';
import '../../deck/widgets/deck_row.dart';
import '../../shared/widgets/adaptive_scaffold.dart';
import '../../shared/widgets/app_semantics.dart';
import '../../shared/widgets/section_widgets.dart';
import '../../shared/widgets/stage_ruler.dart';
import '../../stats/models/stats.dart';
import '../../stats/providers/stats_provider.dart';

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
      ref.read(deckListProvider.notifier).loadDecks();
      ref.read(statsProvider.notifier).loadOverview();
    });
  }

  @override
  Widget build(BuildContext context) {
    final decksAsync = ref.watch(deckListProvider);
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
          await Future.wait([
            ref.read(deckListProvider.notifier).loadDecks(),
            ref.read(statsProvider.notifier).loadOverview(),
          ]);
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
                  const SizedBox(height: 20),
                  if (isTablet)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _HomeMainColumn(statsAsync: statsAsync),
                        ),
                        const SizedBox(width: 30),
                        Expanded(
                          flex: 6,
                          child: _DeckSection(decksAsync: decksAsync),
                        ),
                      ],
                    )
                  else ...[
                    _HomeMainColumn(statsAsync: statsAsync),
                    const SizedBox(height: 24),
                    _DeckSection(decksAsync: decksAsync),
                  ],
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

class _HomeHeader extends StatelessWidget {
  final String initial;

  const _HomeHeader({required this.initial});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('M月d日 EEEE', 'zh_CN').format(DateTime.now());
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Kicker('KARIS REVIEW · 今日'),
              const SizedBox(height: 7),
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
            color: KarisColors.surface,
            border: Border.all(color: KarisColors.hairline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            initial,
            style: const TextStyle(
              color: KarisColors.jade,
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
    final stats = statsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final due = stats?.dueToday ?? 0;
    final reviewed = stats?.reviewedToday ?? 0;
    final distribution = stats?.dueStageDistribution ?? List.filled(9, 0);
    final dominant = _dominantStage(distribution);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: const BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: KarisColors.hairline),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '今日待复习',
                      style: TextStyle(
                        color: KarisColors.jade,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: statsAsync.isLoading ? '--' : '$due',
                            style: karisMono(
                              fontSize: 54,
                              weight: FontWeight.w500,
                            ),
                          ),
                          const TextSpan(
                            text: ' 张',
                            style: TextStyle(
                              color: KarisColors.stone,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      statsAsync.isLoading
                          ? '正在整理今日队列'
                          : '已复习 $reviewed · 还剩 $due',
                      style: const TextStyle(
                        color: KarisColors.stone,
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
        const SizedBox(height: 18),
        const SectionHeader(title: '记忆刻度', trailing: '0-180 天'),
        const SizedBox(height: 14),
        StageRuler(distribution: distribution, currentStage: dominant),
        const SizedBox(height: 10),
        Text(
          statsAsync.isLoading
              ? '正在读取阶段分布'
              : due == 0
              ? '今天没有待复习卡片'
              : '今日到期集中在 ${KarisTheme.stageName(dominant ?? 0)}阶段',
          style: const TextStyle(
            color: KarisColors.stone,
            fontSize: 12,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  int? _dominantStage(List<int> distribution) {
    if (distribution.every((value) => value == 0)) return null;
    var best = 0;
    for (var i = 1; i < distribution.length; i++) {
      if (distribution[i] > distribution[best]) best = i;
    }
    return best;
  }
}

class _DeckSection extends ConsumerWidget {
  final AsyncValue<List<Deck>> decksAsync;

  const _DeckSection({required this.decksAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: '牌组',
          action: TextButton(
            onPressed: () => context.push('/decks'),
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 36),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('新建'),
          ),
        ),
        const SizedBox(height: 6),
        decksAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '加载牌组失败，请检查网络后重试',
                  style: TextStyle(color: KarisColors.cinnabar, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      ref.read(deckListProvider.notifier).loadDecks(),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
          data: (decks) {
            if (decks.isEmpty) {
              return EmptyState(
                icon: Icons.layers_outlined,
                title: '还没有牌组',
                message: '创建第一个牌组，开始记录你的复习队列',
                action: FilledButton.icon(
                  onPressed: () => context.push('/decks'),
                  icon: const Icon(Icons.add, size: 17),
                  label: const Text('创建牌组'),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: decks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final deck = decks[index];
                return DeckRow(
                  name: deck.name,
                  cardCount: deck.cardCount,
                  dueCount: deck.dueCount,
                  newCount: deck.newCount,
                  stageDistribution: deck.stageDistribution,
                  onTap: () => context.push('/decks/${deck.id}/cards'),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
