import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../card/models/card.dart';
import '../../card/providers/card_provider.dart';
import '../../card/pages/card_editor_page.dart';
import '../../deck/providers/deck_provider.dart';
import '../../shared/utils/date_utils.dart';
import '../../shared/utils/motion.dart';
import '../../shared/widgets/adaptive_scaffold.dart';
import '../../shared/widgets/app_semantics.dart';
import '../../shared/widgets/metric_tile.dart';
import '../../shared/widgets/rich_card_content.dart';
import '../../shared/widgets/section_widgets.dart';
import '../../stats/models/stats.dart';
import '../../stats/providers/deck_stats_provider.dart';
import '../../stats/providers/stats_provider.dart';

class CardListPage extends ConsumerStatefulWidget {
  final String deckId;
  final String initialFilter;

  const CardListPage({
    super.key,
    required this.deckId,
    this.initialFilter = 'all',
  });

  @override
  ConsumerState<CardListPage> createState() => _CardListPageState();
}

class _CardListPageState extends ConsumerState<CardListPage> {
  late String _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  @override
  void didUpdateWidget(covariant CardListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilter != oldWidget.initialFilter &&
        widget.initialFilter != _filter) {
      _filter = widget.initialFilter;
    }
  }

  void _setFilter(String value) {
    if (value == _filter) return;
    setState(() => _filter = value);
    GoRouter.maybeOf(
      context,
    )?.replace('/decks/${widget.deckId}/cards?filter=$value');
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(deckStatsProvider(widget.deckId));
    final cardsAsync = ref.watch(
      cardListProvider(CardListArgs(widget.deckId, _filter)),
    );
    final deckName = statsAsync.maybeWhen(
      data: (stats) => stats.deckName,
      orElse: () => '卡片',
    );
    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    return Scaffold(
      backgroundColor: KarisColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, deckName),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref
                      .read(
                        cardListProvider(
                          CardListArgs(widget.deckId, _filter),
                        ).notifier,
                      )
                      .loadCards();
                  ref.invalidate(deckStatsProvider(widget.deckId));
                  ref.invalidate(deckListProvider);
                  ref.invalidate(statsProvider);
                  ref.invalidate(trendProvider(30));
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 980),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildOverview(statsAsync),
                                const SizedBox(height: 18),
                                _buildFilters(statsAsync),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                      sliver: cardsAsync.when(
                        loading: () => const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        error: (error, _) => SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '加载卡片失败，请检查网络后重试',
                                  style: TextStyle(color: KarisColors.cinnabar),
                                ),
                                const SizedBox(height: 10),
                                TextButton(
                                  onPressed: () => ref
                                      .read(
                                        cardListProvider(
                                          CardListArgs(widget.deckId, _filter),
                                        ).notifier,
                                      )
                                      .loadCards(),
                                  child: const Text('重试'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        data: (cards) => cards.isEmpty
                            ? SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 980,
                                    ),
                                    child: EmptyState(
                                      icon: Icons.credit_card_outlined,
                                      title: _filter == 'all'
                                          ? '还没有卡片'
                                          : '当前筛选下没有卡片',
                                      message: _filter == 'all'
                                          ? '新建第一张卡片，开始积累你的记忆刻度'
                                          : '切换到“全部”查看牌组里的所有卡片',
                                      action: _filter == 'all'
                                          ? FilledButton.icon(
                                              onPressed: () => _openEditor(),
                                              icon: const Icon(
                                                Icons.add,
                                                size: 17,
                                              ),
                                              label: const Text('新建卡片'),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              )
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final Widget item;
                                    if (isTablet) {
                                      final start = index * 2;
                                      if (start >= cards.length) {
                                        return const SizedBox.shrink();
                                      }
                                      final first = cards[start];
                                      final second = start + 1 < cards.length
                                          ? cards[start + 1]
                                          : null;
                                      item = Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: RepaintBoundary(
                                              key: ValueKey(first.id),
                                              child: _CardTile(
                                                card: first,
                                                onTap: () =>
                                                    _openEditor(card: first),
                                                onDelete: () =>
                                                    _confirmDelete(first),
                                              ),
                                            ),
                                          ),
                                          if (second != null) ...[
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: RepaintBoundary(
                                                key: ValueKey(second.id),
                                                child: _CardTile(
                                                  card: second,
                                                  onTap: () =>
                                                      _openEditor(card: second),
                                                  onDelete: () =>
                                                      _confirmDelete(second),
                                                ),
                                              ),
                                            ),
                                          ] else
                                            const Expanded(
                                              child: SizedBox.shrink(),
                                            ),
                                        ],
                                      );
                                    } else {
                                      final card = cards[index];
                                      item = RepaintBoundary(
                                        key: ValueKey(card.id),
                                        child: _CardTile(
                                          card: card,
                                          onTap: () => _openEditor(card: card),
                                          onDelete: () => _confirmDelete(card),
                                        ),
                                      );
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: Center(
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 980,
                                          ),
                                          child: item,
                                        ),
                                      ),
                                    );
                                  },
                                  childCount: isTablet
                                      ? (cards.length + 1) ~/ 2
                                      : cards.length,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: KarisColors.ink,
        foregroundColor: KarisColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        icon: const Icon(Icons.add, size: 17),
        label: const Text('新卡片'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String deckName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          KarisIconButton(
            icon: Icons.arrow_back,
            tooltip: '返回',
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Kicker('牌组'),
                const SizedBox(height: 4),
                KarisHeading(
                  child: Text(deckName, style: karisDisplay(fontSize: 25)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          KarisIconButton(
            icon: Icons.upload_file_outlined,
            tooltip: '导入卡片',
            onPressed: () => _openImport(),
          ),
          KarisIconButton(
            icon: Icons.replay,
            tooltip: '复习当前牌组',
            onPressed: () =>
                context.go('/review?mode=due&deck_id=${widget.deckId}'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(AsyncValue<DeckStats> statsAsync) {
    final stats = statsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    return Row(
      children: [
        Expanded(
          child: MetricTile(
            label: '卡片',
            value: stats == null ? '--' : '${stats.totalCards}',
            icon: Icons.credit_card_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: MetricTile(
            label: '今日待复习',
            value: stats == null ? '--' : '${stats.dueToday}',
            valueColor: KarisColors.cinnabar,
            icon: Icons.schedule_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: MetricTile(
            label: '已掌握',
            value: stats == null ? '--' : '${stats.masteredCards}',
            valueColor: KarisColors.jade,
            icon: Icons.done_all_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(AsyncValue<DeckStats?> statsAsync) {
    final stats = statsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final filters = [
      ('all', '全部', stats?.totalCards ?? 0),
      ('due', '待复习', stats?.dueToday ?? 0),
      ('learning', '重学', stats?.learningCards ?? 0),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in filters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: filter.$2,
                count: filter.$3,
                active: _filter == filter.$1,
                onTap: () => _setFilter(filter.$1),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openEditor({FlashCard? card}) async {
    final result = await context.push<(String, String)>(
      '/decks/${widget.deckId}/cards/editor',
      extra: CardEditorArgs(
        deckId: widget.deckId,
        cardId: card?.id,
        initialFront: card?.front,
        initialBack: card?.back,
      ),
    );
    if (result == null || !mounted) return;
    _refreshAfterChange();
  }

  Future<void> _openImport() async {
    final count = await context.push<int>(
      '/decks/${widget.deckId}/cards/import',
    );
    if (count == null || !mounted) return;
    _refreshAfterChange();
    final message = '已导入 $count 张卡片';
    announceMessage(context, message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _refreshAfterChange() {
    ref.invalidate(cardListProvider(CardListArgs(widget.deckId, _filter)));
    ref.invalidate(deckStatsProvider(widget.deckId));
    ref.invalidate(deckListProvider);
    ref.invalidate(statsProvider);
    ref.invalidate(trendProvider(30));
  }

  void _confirmDelete(FlashCard card) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('删除卡片'),
          content: const Text('确定要删除这张卡片吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: KarisColors.cinnabar,
                foregroundColor: KarisColors.surface,
              ),
              onPressed: () async {
                await ref
                    .read(
                      cardListProvider(
                        CardListArgs(widget.deckId, _filter),
                      ).notifier,
                    )
                    .deleteCard(card.id);
                ref.invalidate(deckStatsProvider(widget.deckId));
                ref.invalidate(deckListProvider);
                ref.invalidate(statsProvider);
                ref.invalidate(trendProvider(30));
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return KarisInteractive(
      selected: active,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: reducedDuration(context, const Duration(milliseconds: 180)),
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: active ? KarisColors.jadeSoft : KarisColors.surface,
            border: Border.all(
              color: active ? KarisColors.jade : KarisColors.hairline,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: active ? KarisColors.jade : KarisColors.stone,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '$count',
                style: karisMono(
                  fontSize: 10,
                  color: active ? KarisColors.jade : KarisColors.stone,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final FlashCard card;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CardTile({
    required this.card,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final nextLabel = _nextLabel();
    return KarisInteractive(
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: KarisColors.surface,
            border: Border.all(color: KarisColors.hairline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StageBadge(stage: card.stage, learning: card.learningMode),
                  const Spacer(),
                  Text(
                    nextLabel,
                    style: karisMono(fontSize: 10, color: KarisColors.stone),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    tooltip: '删除卡片',
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 17,
                      color: KarisColors.cinnabar,
                    ),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(36, 36),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              RichCardContent(
                content: card.front,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: KarisColors.ink,
                  height: 1.5,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 4),
              RichCardContent(
                content: card.back,
                style: const TextStyle(
                  fontSize: 13,
                  color: KarisColors.stone,
                  height: 1.5,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _nextLabel() {
    if (card.learningMode) {
      final goal = card.learningGoal ?? 5;
      return '重学 ${card.consecutiveFamiliar}/$goal';
    }
    if (card.due) return '今天';
    final date = card.nextReviewDate;
    if (date == null) return '新卡';
    return AppDateUtils.relativeDate(DateTime.parse(date));
  }
}

class _StageBadge extends StatelessWidget {
  final int stage;
  final bool learning;

  const _StageBadge({required this.stage, required this.learning});

  @override
  Widget build(BuildContext context) {
    final color = learning ? KarisColors.amber : KarisColors.jade;
    final background = learning ? KarisColors.amberSoft : KarisColors.jadeSoft;
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        learning ? '重学' : KarisTheme.stageName(stage),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
