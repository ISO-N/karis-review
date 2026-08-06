import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../card/models/card.dart';
import '../../card/models/card_import.dart';
import '../../card/providers/card_provider.dart';
import '../../card/pages/card_editor_page.dart';
import '../../deck/providers/deck_provider.dart';
import '../../shared/utils/motion.dart';
import '../../shared/widgets/adaptive_scaffold.dart';
import '../../shared/widgets/app_feedback.dart';
import '../../shared/widgets/app_semantics.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/loading_widget.dart';
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
  bool _selecting = false;
  final Set<String> _selectedIds = {};
  late final TextEditingController _searchController;
  final FocusNode _searchFocus = FocusNode();
  Timer? _searchDebounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CardListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.deckId != oldWidget.deckId) {
      _searchDebounce?.cancel();
      _searchController.clear();
      _query = '';
      _filter = widget.initialFilter;
      return;
    }
    if (widget.initialFilter != oldWidget.initialFilter &&
        widget.initialFilter != _filter) {
      _filter = widget.initialFilter;
      _selectedIds.clear();
    }
  }

  void _setFilter(String value) {
    if (value == _filter) return;
    setState(() {
      _filter = value;
      _selectedIds.clear();
    });
    final notifier = ref.read(
      cardListProvider(CardListArgs(widget.deckId, value)).notifier,
    );
    unawaited(notifier.setSearchQuery(_query));
    GoRouter.maybeOf(
      context,
    )?.replace('/decks/${widget.deckId}/cards?filter=$value');
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final query = value.trim();
      if (query == _query) return;
      setState(() => _query = query);
      unawaited(
        ref
            .read(
              cardListProvider(CardListArgs(widget.deckId, _filter)).notifier,
            )
            .setSearchQuery(query),
      );
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    if (_query.isEmpty) return;
    setState(() => _query = '');
    unawaited(
      ref
          .read(cardListProvider(CardListArgs(widget.deckId, _filter)).notifier)
          .setSearchQuery(''),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
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
      backgroundColor: colors.paper,
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
                                _buildSearchField(),
                                const SizedBox(height: 14),
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
                          child: LoadingWidget(),
                        ),
                        error: (error, _) => SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '加载卡片失败，请检查网络后重试',
                                  style: TextStyle(color: colors.cinnabar),
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
                                      title: _query.isNotEmpty
                                          ? '没有匹配的卡片'
                                          : _filter == 'all'
                                          ? '还没有卡片'
                                          : '当前筛选下没有卡片',
                                      message: _query.isNotEmpty
                                          ? '换个关键词，或清除搜索后查看当前筛选'
                                          : _filter == 'all'
                                          ? '新建第一张卡片，开始积累你的记忆刻度'
                                          : '切换到"全部"查看卡组里的所有卡片',
                                      action: _query.isNotEmpty
                                          ? TextButton(
                                              onPressed: _clearSearch,
                                              child: const Text('清除搜索'),
                                            )
                                          : _filter == 'all'
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
                                                selecting: _selecting,
                                                selected: _selectedIds.contains(
                                                  first.id,
                                                ),
                                                onTap: () => _selecting
                                                    ? _toggleSelection(first.id)
                                                    : _openEditor(card: first),
                                                onDelete: _selecting
                                                    ? null
                                                    : () =>
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
                                                  selecting: _selecting,
                                                  selected: _selectedIds
                                                      .contains(second.id),
                                                  onTap: () => _selecting
                                                      ? _toggleSelection(
                                                          second.id,
                                                        )
                                                      : _openEditor(
                                                          card: second,
                                                        ),
                                                  onDelete: _selecting
                                                      ? null
                                                      : () => _confirmDelete(
                                                          second,
                                                        ),
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
                                          selecting: _selecting,
                                          selected: _selectedIds.contains(
                                            card.id,
                                          ),
                                          onTap: () => _selecting
                                              ? _toggleSelection(card.id)
                                              : _openEditor(card: card),
                                          onDelete: _selecting
                                              ? null
                                              : () => _confirmDelete(card),
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
                                          child: KarisEntrance(
                                            delay: KarisMotion.staggerDelay(
                                              index * 2,
                                            ),
                                            child: item,
                                          ),
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
      bottomNavigationBar: _selecting ? _buildSelectionBar(cardsAsync) : null,
      floatingActionButton: _selecting
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openEditor(),
              backgroundColor: colors.ink,
              foregroundColor: colors.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              icon: const Icon(Icons.add, size: 17),
              label: const Text('新卡片'),
            ),
    );
  }

  Widget _buildHeader(BuildContext context, String deckName) {
    final colors = context.karisColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          KarisIconButton(
            icon: _selecting ? Icons.close : Icons.arrow_back,
            tooltip: _selecting ? '退出多选' : '返回',
            onPressed: _selecting
                ? () => _toggleSelecting(false)
                : () => context.pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Kicker('卡组'),
                const SizedBox(height: 4),
                KarisHeading(
                  child: Text(deckName, style: karisDisplay(fontSize: 25)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (_selecting)
            Text(
              '已选 ${_selectedIds.length} 张',
              style: karisMono(fontSize: 12, color: colors.jade),
            )
          else ...[
            KarisIconButton(
              icon: Icons.checklist,
              tooltip: '多选',
              onPressed: () => _toggleSelecting(true),
            ),
            KarisIconButton(
              icon: Icons.upload_file_outlined,
              tooltip: '导入卡片',
              onPressed: () => _openImport(),
            ),
            KarisIconButton(
              icon: Icons.replay,
              tooltip: '复习当前卡组',
              onPressed: () =>
                  context.go('/review?mode=due&deck_id=${widget.deckId}'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverview(AsyncValue<DeckStats> statsAsync) {
    final colors = context.karisColors;
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
            valueColor: colors.cinnabar,
            icon: Icons.schedule_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: MetricTile(
            label: '已掌握',
            value: stats == null ? '--' : '${stats.masteredCards}',
            valueColor: colors.jade,
            icon: Icons.done_all_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    final colors = context.karisColors;
    return TextField(
      controller: _searchController,
      focusNode: _searchFocus,
      maxLength: 100,
      textInputAction: TextInputAction.search,
      onChanged: _onSearchChanged,
      onSubmitted: (_) => _searchFocus.unfocus(),
      decoration: InputDecoration(
        hintText: '搜索正面或反面',
        counterText: '',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _searchController,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.close, size: 19),
              tooltip: '清除搜索',
              onPressed: _clearSearch,
            );
          },
        ),
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.jade),
        ),
      ),
    );
  }

  Widget _buildFilters(AsyncValue<DeckStats?> statsAsync) {
    final stats = statsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final filters = [
      ('all', '全部', stats?.totalCards ?? 0),
      ('new', '新卡', stats?.newCards ?? 0),
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

  void _toggleSelecting(bool value) {
    setState(() {
      _selecting = value;
      if (!value) _selectedIds.clear();
    });
  }

  void _toggleSelection(String cardId) {
    setState(() {
      if (!_selectedIds.remove(cardId)) {
        _selectedIds.add(cardId);
      }
    });
  }

  Future<void> _openImport() async {
    final colors = context.karisColors;
    final result = await context.push<CardImportResult>(
      '/decks/${widget.deckId}/cards/import',
    );
    if (result == null || !mounted) return;
    _refreshAfterChange();
    final count = result.importedCards;
    announceMessage(context, '已导入 $count 张卡片');
    // 用常驻 Banner 替代 4 秒 SnackBar：不自动消失，避免误触；
    // 文案写明撤销的后果（删除刚导入的卡片，不可恢复）。
    final messenger = ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..hideCurrentMaterialBanner();
    messenger.showMaterialBanner(
      MaterialBanner(
        leading: Icon(Icons.undo, size: 20, color: colors.jade),
        content: Text('已导入 $count 张卡片，可撤销导入（将删除这批卡片，不可恢复）'),
        actions: [
          TextButton(
            onPressed: messenger.hideCurrentMaterialBanner,
            child: const Text('知道了'),
          ),
          if (result.importedCardIds.isNotEmpty)
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: colors.jadeSoft,
                foregroundColor: colors.jade,
                minimumSize: const Size(0, 40),
              ),
              onPressed: () async {
                messenger.hideCurrentMaterialBanner();
                final ok = await _confirmUndoImport(count);
                if (ok == true && mounted) {
                  await _undoImport(result.importedCardIds);
                }
              },
              child: Text('撤销导入（$count 张）'),
            ),
        ],
      ),
    );
  }

  Future<bool?> _confirmUndoImport(int count) {
    final colors = context.karisColors;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('撤销导入'),
        content: Text('将删除刚导入的 $count 张卡片，此操作不可恢复。确定要撤销吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.cinnabar,
              foregroundColor: colors.surface,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('撤销导入'),
          ),
        ],
      ),
    );
  }

  Future<void> _undoImport(List<String> cardIds) async {
    final args = CardListArgs(widget.deckId, _filter);
    await ref.read(cardListProvider(args).notifier).deleteCards(cardIds);
    if (!mounted) return;
    if (ref.read(cardListProvider(args)).hasError) {
      _showMessage('撤销失败，请重试', KarisFeedbackTone.error);
      return;
    }
    _refreshAfterChange();
    _showMessage(
      '已撤销导入，已删除 ${cardIds.length} 张卡片',
      KarisFeedbackTone.success,
    );
  }

  void _showMessage(String message, KarisFeedbackTone tone) {
    if (!mounted) return;
    announceMessage(context, message);
    showKarisFeedback(context, tone: tone, title: message);
  }

  Widget _buildSelectionBar(AsyncValue<List<FlashCard>> cardsAsync) {
    final colors = context.karisColors;
    final cards = cardsAsync.valueOrNull ?? const <FlashCard>[];
    final allSelected =
        cards.isNotEmpty &&
        cards.every((card) => _selectedIds.contains(card.id));
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border(top: BorderSide(color: colors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            KarisIconButton(
              icon: Icons.close,
              tooltip: '退出多选',
              onPressed: () => _toggleSelecting(false),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    if (allSelected) {
                      _selectedIds.clear();
                    } else {
                      _selectedIds.addAll(cards.map((card) => card.id));
                    }
                  });
                },
                icon: const Icon(Icons.select_all, size: 17),
                label: Text(allSelected ? '取消全选' : '全选'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  foregroundColor: colors.jade,
                  side: BorderSide(color: colors.hairline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                icon: const Icon(Icons.delete_outline, size: 17),
                label: Text('删除所选（${_selectedIds.length}）'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  backgroundColor: colors.cinnabar,
                  foregroundColor: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSelected() async {
    final colors = context.karisColors;
    final cardIds = _selectedIds.toList();
    if (cardIds.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定要删除选中的 ${cardIds.length} 张卡片吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.cinnabar,
              foregroundColor: colors.surface,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final args = CardListArgs(widget.deckId, _filter);
    await ref.read(cardListProvider(args).notifier).deleteCards(cardIds);
    if (!mounted) return;
    if (ref.read(cardListProvider(args)).hasError) {
      _showMessage('删除失败，请检查网络后重试', KarisFeedbackTone.error);
      return;
    }
    setState(() {
      _selecting = false;
      _selectedIds.clear();
    });
    _refreshAfterChange();
    _showMessage('已删除 ${cardIds.length} 张卡片', KarisFeedbackTone.success);
  }

  void _refreshAfterChange() {
    ref.invalidate(cardListProvider(CardListArgs(widget.deckId, _filter)));
    ref.invalidate(deckStatsProvider(widget.deckId));
    ref.invalidate(deckListProvider);
    ref.invalidate(statsProvider);
    ref.invalidate(trendProvider(30));
    if (_query.isNotEmpty) {
      unawaited(
        ref
            .read(
              cardListProvider(CardListArgs(widget.deckId, _filter)).notifier,
            )
            .setSearchQuery(_query),
      );
    }
  }

  void _confirmDelete(FlashCard card) {
    final colors = context.karisColors;
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
                backgroundColor: colors.cinnabar,
                foregroundColor: colors.surface,
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
    final colors = context.karisColors;
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
            color: active ? colors.jadeSoft : colors.surface,
            border: Border.all(
              color: active ? colors.jade : colors.hairline,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: active ? colors.jade : colors.stone,
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
                  color: active ? colors.jade : colors.stone,
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
  final VoidCallback? onDelete;
  final bool selecting;
  final bool selected;

  const _CardTile({
    required this.card,
    required this.onTap,
    this.onDelete,
    this.selecting = false,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    final nextLabel = _nextLabel();
    return KarisInteractive(
      child: InkWell(
        onTap: onTap,
        onLongPress: selecting ? onTap : onDelete,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: selected ? colors.jadeSoft : colors.surface,
            border: Border.all(
              color: selected ? colors.jade : colors.hairline,
            ),
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
                    style: karisMono(fontSize: 10, color: colors.stone),
                  ),
                  if (selecting)
                    Checkbox(
                      value: selected,
                      onChanged: (_) => onTap(),
                      activeColor: colors.jade,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                  else
                    IconButton(
                      onPressed: onDelete,
                      tooltip: '删除卡片',
                      icon: Icon(
                        Icons.delete_outline,
                        size: 17,
                        color: colors.cinnabar,
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.ink,
                  height: 1.5,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 4),
              RichCardContent(
                content: card.back,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.stone,
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
    final parsed = DateTime.parse(date);
    final now = DateTime.now();
    if (parsed.year == now.year) {
      return '${parsed.month}月${parsed.day}日';
    }
    return '${parsed.year}年${parsed.month}月${parsed.day}日';
  }
}

class _StageBadge extends StatelessWidget {
  final int stage;
  final bool learning;

  const _StageBadge({required this.stage, required this.learning});

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    final (String label, Color color, Color background) = switch ((stage, learning)) {
      (_, true) => ('重学', colors.amber, colors.amberSoft),
      (0, false) => ('新卡', colors.jade, colors.jadeSoft),
      (8, false) => ('掌握', colors.jade, colors.jadeSoft),
      _ => ('复习', colors.jade, colors.jadeSoft),
    };
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
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
