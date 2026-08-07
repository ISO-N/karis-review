import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
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
  // 多选状态独立于页面 setState：点选/全选时只重建受影响的 tile 与计数 UI，
  // 避免 5k 大列表下整页（统计区/筛选区/所有可见 tile）随每次点选重建。
  final _CardSelectionController _selection = _CardSelectionController();
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
    _selection.dispose();
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
      _selection.clearSilently();
    }
  }

  void _setFilter(String value) {
    if (value == _filter) return;
    setState(() {
      _filter = value;
    });
    _selection.clearSilently();
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
                  // ignore: unused_result
                  ref.refresh(trendProvider(30));
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  // 5k+ 卡片大列表：缩小预构建范围，避免拖动 thumb 时
                  // 大量刚预构建的 item 因位置跳变立即失效。
                  scrollCacheExtent: const ScrollCacheExtent.pixels(150),
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
                      // 顶部留 12px：避免筛选栏（全部/新卡/待复习/重学）与卡片列表紧贴。
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
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
                                                selection: _selection,
                                                onTap: () => _selection
                                                        .selecting
                                                    ? _selection.toggle(first.id)
                                                    : _openEditor(card: first),
                                                onDelete: _selection.selecting
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
                                                  selection: _selection,
                                                  onTap: () => _selection
                                                          .selecting
                                                      ? _selection.toggle(
                                                          second.id,
                                                        )
                                                      : _openEditor(
                                                          card: second,
                                                        ),
                                                  onDelete: _selection.selecting
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
                                          selection: _selection,
                                          onTap: () => _selection.selecting
                                              ? _selection.toggle(card.id)
                                              : _openEditor(card: card),
                                          onDelete: _selection.selecting
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
                                              index * (isTablet ? 2 : 1),
                                            ),
                                            // 仅首屏约 12 张播放入场动画；
                                            // 滚动加载的项直接渲染，避免深层延迟与动画掉帧。
                                            play: index * (isTablet ? 2 : 1) <
                                                12,
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
      // 底部操作条与 FAB 的显隐依赖多选状态：各自用 ListenableBuilder 隔离，
      // 进入/退出多选或点选计数变化时只重建这条 UI，列表主体不参与。
      // 非多选时返回 SizedBox.shrink 保持 builder 返回非空 Widget（Scaffold 渲染零尺寸）。
      bottomNavigationBar: ListenableBuilder(
        listenable: _selection,
        builder: (context, _) => _selection.selecting
            ? _buildSelectionBar(cardsAsync)
            : const SizedBox.shrink(),
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _selection,
        builder: (context, _) => _selection.selecting
            ? const SizedBox.shrink()
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
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String deckName) {
    final colors = context.karisColors;
    return ListenableBuilder(
      listenable: _selection,
      builder: (context, _) {
        final selecting = _selection.selecting;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            children: [
              KarisIconButton(
                icon: selecting ? Icons.close : Icons.arrow_back,
                tooltip: selecting ? '退出多选' : '返回',
                onPressed: selecting
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
              if (selecting)
                Text(
                  '已选 ${_selection.count} 张',
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
      },
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
    _selection.setSelecting(value);
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
        cards.every((card) => _selection.isSelected(card.id));
    final selectedCount = _selection.count;
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
                onPressed: () => _selection.toggleAll(
                  cards.map((card) => card.id),
                ),
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
                onPressed: selectedCount == 0 ? null : _deleteSelected,
                icon: const Icon(Icons.delete_outline, size: 17),
                label: Text('删除所选（$selectedCount）'),
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
    final cardIds = _selection.selectedIds.toList();
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
    _selection.setSelecting(false);
    _refreshAfterChange();
    _showMessage('已删除 ${cardIds.length} 张卡片', KarisFeedbackTone.success);
  }

  void _refreshAfterChange() {
    ref.invalidate(cardListProvider(CardListArgs(widget.deckId, _filter)));
    ref.invalidate(deckStatsProvider(widget.deckId));
    ref.invalidate(deckListProvider);
    ref.invalidate(statsProvider);
    // ignore: unused_result
    ref.refresh(trendProvider(30));
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
                // ignore: unused_result
                ref.refresh(trendProvider(30));
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

/// 多选状态控制器：把选择状态从页面级 setState 中剥离。
///
/// 列表项各自订阅本控制器，点选/全选时只有「选中态真正变化」的 tile
/// 才重建自身；统计区、筛选区、搜索框与其他 tile 完全不受影响，
/// 这是 5k 卡片列表多选交互不卡的关键。
class _CardSelectionController extends ChangeNotifier {
  bool _selecting = false;
  final Set<String> _selectedIds = <String>{};

  bool get selecting => _selecting;
  int get count => _selectedIds.length;
  Set<String> get selectedIds => _selectedIds;

  bool isSelected(String id) => _selectedIds.contains(id);

  void toggle(String id) {
    if (!_selectedIds.remove(id)) {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void setSelecting(bool value) {
    if (_selecting == value) return;
    _selecting = value;
    if (!value) _selectedIds.clear();
    notifyListeners();
  }

  void toggleAll(Iterable<String> ids) {
    final list = ids.toList();
    final allSelected =
        list.isNotEmpty && list.every(_selectedIds.contains);
    if (allSelected) {
      _selectedIds.removeAll(list);
    } else {
      _selectedIds.addAll(list);
    }
    notifyListeners();
  }

  /// 静默清空：用于筛选/卡组切换等伴随列表整体重建的场景，
  /// 不触发通知（tile 会随重建重新同步状态，避免 build 期间 setState）。
  void clearSilently() {
    _selectedIds.clear();
  }
}

class _CardTile extends StatefulWidget {
  final FlashCard card;
  final _CardSelectionController selection;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _CardTile({
    required this.card,
    required this.selection,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<_CardTile> createState() => _CardTileState();
}

class _CardTileState extends State<_CardTile> {
  late bool _selecting;
  late bool _selected;

  @override
  void initState() {
    super.initState();
    widget.selection.addListener(_onSelectionChanged);
    _selecting = widget.selection.selecting;
    _selected = widget.selection.isSelected(widget.card.id);
  }

  @override
  void didUpdateWidget(covariant _CardTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.id != widget.card.id) {
      // Sliver 复用同一 element 时 card 可能变化：在 build 前直接同步状态。
      _selecting = widget.selection.selecting;
      _selected = widget.selection.isSelected(widget.card.id);
      return;
    }
    if (!identical(oldWidget.selection, widget.selection)) {
      oldWidget.selection.removeListener(_onSelectionChanged);
      widget.selection.addListener(_onSelectionChanged);
      _selecting = widget.selection.selecting;
      _selected = widget.selection.isSelected(widget.card.id);
    }
  }

  @override
  void dispose() {
    widget.selection.removeListener(_onSelectionChanged);
    super.dispose();
  }

  void _onSelectionChanged() {
    final selected = widget.selection.isSelected(widget.card.id);
    final selecting = widget.selection.selecting;
    // 选中态没变的 tile 直接返回：点选一张时只有它自己重建。
    if (selected == _selected && selecting == _selecting) return;
    setState(() {
      _selected = selected;
      _selecting = selecting;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    final nextLabel = _nextLabel();
    final selected = _selected;
    final selecting = _selecting;
    return KarisInteractive(
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: selecting ? widget.onTap : widget.onDelete,
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
                  _StageBadge(
                    stage: widget.card.stage,
                    learning: widget.card.learningMode,
                  ),
                  const Spacer(),
                  Text(
                    nextLabel,
                    style: karisMono(fontSize: 10, color: colors.stone),
                  ),
                  if (selecting)
                    Checkbox(
                      value: selected,
                      onChanged: (_) => widget.onTap(),
                      activeColor: colors.jade,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                  else
                    IconButton(
                      onPressed: widget.onDelete,
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
                content: widget.card.front,
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
                content: widget.card.back,
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

  /// 纯字符串解析 'YYYY-MM-DD'，避免 5k 大列表滚动时每个可见项
  /// 重复 DateTime.parse + 日期对象比较。
  String _nextLabel() {
    final card = widget.card;
    if (card.learningMode) {
      final goal = card.learningGoal ?? 5;
      return '重学 ${card.consecutiveFamiliar}/$goal';
    }
    if (card.due) return '今天';
    final date = card.nextReviewDate;
    if (date == null || date.isEmpty) return '新卡';
    final parts = date.split('-');
    if (parts.length != 3) return '新卡';
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    if (year == DateTime.now().year) return '$month月$day日';
    return '$year年$month月$day日';
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
