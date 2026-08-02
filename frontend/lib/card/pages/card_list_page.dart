import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../card/models/card.dart';
import '../../card/providers/card_provider.dart';
import '../../card/widgets/card_editor_sheet.dart';
import '../../card/widgets/card_import_sheet.dart';
import '../../deck/providers/deck_provider.dart';
import '../../shared/utils/date_utils.dart';
import '../../shared/widgets/adaptive_scaffold.dart';
import '../../shared/widgets/metric_tile.dart';
import '../../shared/widgets/rich_card_content.dart';
import '../../shared/widgets/section_widgets.dart';
import '../../stats/models/stats.dart';
import '../../stats/providers/deck_stats_provider.dart';

class CardListPage extends ConsumerStatefulWidget {
  final String deckId;

  const CardListPage({super.key, required this.deckId});

  @override
  ConsumerState<CardListPage> createState() => _CardListPageState();
}

class _CardListPageState extends ConsumerState<CardListPage> {
  String _filter = 'all';

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
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOverview(statsAsync),
                          const SizedBox(height: 18),
                          _buildFilters(statsAsync),
                          cardsAsync.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 60),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            error: (error, _) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                children: [
                                  const Text(
                                    '加载卡片失败',
                                    style: TextStyle(
                                      color: KarisColors.cinnabar,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextButton(
                                    onPressed: () => ref
                                        .read(
                                          cardListProvider(
                                            CardListArgs(
                                              widget.deckId,
                                              _filter,
                                            ),
                                          ).notifier,
                                        )
                                        .loadCards(),
                                    child: const Text('重试'),
                                  ),
                                ],
                              ),
                            ),
                            data: (cards) => cards.isEmpty
                                ? EmptyState(
                                    icon: Icons.credit_card_outlined,
                                    title: _filter == 'all'
                                        ? '还没有卡片'
                                        : '当前筛选下没有卡片',
                                    message: _filter == 'all'
                                        ? '新建第一张卡片，开始积累你的记忆刻度'
                                        : '切换到“全部”查看牌组里的所有卡片',
                                    action: _filter == 'all'
                                        ? FilledButton.icon(
                                            onPressed: () =>
                                                _openEditor(context),
                                            icon: const Icon(
                                              Icons.add,
                                              size: 17,
                                            ),
                                            label: const Text('新建卡片'),
                                          )
                                        : null,
                                  )
                                : LayoutBuilder(
                                    builder: (context, constraints) {
                                      final isTablet =
                                          constraints.maxWidth >= 640;
                                      final itemWidth = isTablet
                                          ? (constraints.maxWidth - 10) / 2
                                          : constraints.maxWidth;
                                      return Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: [
                                          for (final card in cards)
                                            SizedBox(
                                              width: itemWidth,
                                              child: _CardTile(
                                                card: card,
                                                onTap: () => _openEditor(
                                                  context,
                                                  card: card,
                                                ),
                                                onDelete: () =>
                                                    _confirmDelete(card),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
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
                Text(deckName, style: karisDisplay(fontSize: 25)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          KarisIconButton(
            icon: Icons.upload_file_outlined,
            tooltip: '导入卡片',
            onPressed: () => _openImport(context),
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
                onTap: () => setState(() => _filter = filter.$1),
              ),
            ),
        ],
      ),
    );
  }

  void _openEditor(BuildContext context, {FlashCard? card}) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CardEditorSheet(
        deckId: widget.deckId,
        cardId: card?.id,
        initialFront: card?.front,
        initialBack: card?.back,
        onSaved: (_) {
          ref.invalidate(
            cardListProvider(CardListArgs(widget.deckId, _filter)),
          );
          ref.invalidate(deckStatsProvider(widget.deckId));
          ref.invalidate(deckListProvider);
        },
      ),
    );
  }

  void _openImport(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CardImportSheet(
        deckId: widget.deckId,
        onImported: (count) {
          ref.invalidate(
            cardListProvider(CardListArgs(widget.deckId, _filter)),
          );
          ref.invalidate(deckStatsProvider(widget.deckId));
          ref.invalidate(deckListProvider);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('已导入 $count 张卡片')));
        },
      ),
    );
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
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
    return InkWell(
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
