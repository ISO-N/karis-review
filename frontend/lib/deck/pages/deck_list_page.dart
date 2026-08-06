import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../deck/models/deck.dart';
import '../../deck/providers/deck_provider.dart';
import '../../deck/widgets/deck_row.dart';
import '../../shared/widgets/adaptive_scaffold.dart';
import '../../shared/widgets/app_feedback.dart';
import '../../shared/widgets/app_semantics.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/section_widgets.dart';
import '../../shared/utils/motion.dart';
import '../../stats/providers/stats_provider.dart';

import '../../l10n/app_localizations.dart';
class DeckListPage extends ConsumerStatefulWidget {
  const DeckListPage({super.key});

  @override
  ConsumerState<DeckListPage> createState() => _DeckListPageState();
}

class _DeckListPageState extends ConsumerState<DeckListPage> {
  late final TextEditingController _searchController;
  final FocusNode _searchFocus = FocusNode();
  Timer? _searchDebounce;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final query = value.trim();
      if (query == _searchQuery) return;
      setState(() => _searchQuery = query);
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    if (_searchQuery.isEmpty) return;
    setState(() => _searchQuery = '');
  }
  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    final l10n = KarisReviewLocalizations.of(context)!;
    final decksAsync = ref.watch(deckListProvider);
    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    final decks = decksAsync.maybeWhen(
      data: (d) => d,
      orElse: () => const <Deck>[],
    );
    final filtered = _searchQuery.isEmpty
        ? decks
        : decks.where((d) =>
            d.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          ).toList();

    return AdaptiveAppScaffold(
      current: KarisNavItem.decks,
      onSelect: (item) => _go(item, context),
      body: RefreshIndicator(
        onRefresh: () => ref.read(deckListProvider.notifier).loadDecks(),
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
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Kicker('DECKS'),
                            SizedBox(height: 7),
                            KarisHeading(
                              child: Text(
                                l10n.navDecks,
                                style: karisDisplay(fontSize: 27),
                              ),
                            ),
                          ],
                        ),
                      ),
                      KarisIconButton(
                        icon: Icons.add,
                        tooltip: l10n.deckCreateTitle,
                        onPressed: () => _showDeckDialog(ref),
                      ),
                    ],
                  ),
                  SizedBox(height: 18),
                  _buildSearchField(),
                  SizedBox(height: 14),
                  SectionHeader(
                    title: l10n.deckListTitle,
                    trailing: _searchQuery.isEmpty
                        ? '${filtered.length} 个卡组'
                        : '搜索到 ${filtered.length} 个',
                  ),
                  SizedBox(height: 12),
                  if (decksAsync.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: _DeckListSkeleton(),
                    )
                  else if (decksAsync.hasError)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Text(
                            l10n.errorLoadFailed,
                            style: TextStyle(color: colors.cinnabar),
                          ),
                          SizedBox(height: 10),
                          TextButton(
                            onPressed: () =>
                                ref.read(deckListProvider.notifier).loadDecks(),
                            child: Text(l10n.errorRetry),
                          ),
                        ],
                      ),
                    )
                  else if (filtered.isEmpty)
                    EmptyState(
                      icon: Icons.layers_outlined,
                      title: _searchQuery.isNotEmpty
                          ? '没有匹配的卡组'
                          : l10n.homeNoDecksTitle,
                      message: _searchQuery.isNotEmpty
                          ? '换个关键词试试'
                          : l10n.homeNoDecksMessage,
                      action: _searchQuery.isNotEmpty
                          ? TextButton(
                              onPressed: _clearSearch,
                              child: const Text('清除搜索'),
                            )
                          : FilledButton.icon(
                              onPressed: () => _showDeckDialog(ref),
                              icon: const Icon(Icons.add, size: 17),
                              label: Text(l10n.deckCreateButton),
                            ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final deck = filtered[index];
                        return KarisEntrance(
                          delay: KarisMotion.staggerDelay(index),
                          // 仅首屏 8 个卡组播放入场动画，其余直接渲染。
                          play: index < 8,
                          child: DeckRow(
                            name: deck.name,
                            cardCount: deck.cardCount,
                            dueCount: deck.dueCount,
                            newCount: deck.newCount,
                            stageDistribution: deck.stageDistribution,
                            onTap: () =>
                                context.push('/decks/${deck.id}/cards'),
                            onEdit: () =>
                                _showDeckDialog(ref, deck: deck),
                            onDelete: () =>
                                _confirmDeleteDeck(context, ref, deck),
                          ),
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
        hintText: '搜索卡组名称',
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

  void _showDeckDialog(WidgetRef ref, {Deck? deck}) {
    showDialog<void>(
      context: context,
      builder: (_) => _DeckDialog(deck: deck),
    );
  }
}

class _DeckDialog extends ConsumerStatefulWidget {
  final Deck? deck;

  const _DeckDialog({this.deck});

  @override
  ConsumerState<_DeckDialog> createState() => _DeckDialogState();
}

class _DeckDialogState extends ConsumerState<_DeckDialog> {
  KarisReviewLocalizations get l10n => KarisReviewLocalizations.of(context)!;
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.deck?.name ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    final notifier = ref.read(deckListProvider.notifier);
    final deck = widget.deck;
    if (deck == null) {
      await notifier.createDeck(name);
    } else {
      await notifier.updateDeck(deck.id, name);
    }
    if (!mounted) return;
    if (ref.read(deckListProvider).hasError) {
      setState(() => _saving = false);
      showKarisFeedback(context, tone: KarisFeedbackTone.error, title: l10n.errorSaveFailed);
      return;
    }
    ref.invalidate(statsProvider);
    ref.invalidate(trendProvider(30));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: KarisHeading(child: Text(widget.deck == null ? l10n.deckCreateTitle : l10n.deckRenameTitle)),
      content: TextField(
        controller: _controller,
        autofocus: shouldAutoFocus(context),
        autofillHints: const [AutofillHints.name],
        maxLength: 100,
        decoration: InputDecoration(
          labelText: l10n.deckNameLabel,
          hintText: l10n.deckNameHint,
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.deck == null ? l10n.deckCreateButton : l10n.deckSaveButton),
        ),
      ],
    );
  }
}

void _confirmDeleteDeck(BuildContext context, WidgetRef ref, Deck deck) {
  final colors = context.karisColors;
  final l10n = KarisReviewLocalizations.of(context)!;
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.deckDeleteTitle),
        content: Text('确定要删除“${deck.name}”吗？卡组内的所有卡片和复习记录也会删除。'),
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
              await ref.read(deckListProvider.notifier).deleteDeck(deck.id);
              ref.invalidate(statsProvider);
              ref.invalidate(trendProvider(30));
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: Text(l10n.deckDeleteLabel),
          ),
        ],
      );
    },
  );
}

/// 卡组列表加载骨架：模拟三行卡组项，shimmer 流光扫过。
class _DeckListSkeleton extends StatelessWidget {
  const _DeckListSkeleton();

  @override
  Widget build(BuildContext context) {
    return KarisSkeletonGroup(
      child: Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            Container(
              height: 76,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: context.karisColors.surface,
                border: Border.all(color: context.karisColors.hairline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const KarisSkeleton(width: 36, height: 36, borderRadius: BorderRadius.all(Radius.circular(8))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        KarisSkeleton(width: 140, height: 13),
                        SizedBox(height: 8),
                        KarisSkeleton(width: 90, height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
