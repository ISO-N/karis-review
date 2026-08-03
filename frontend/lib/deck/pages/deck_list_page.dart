import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../deck/models/deck.dart';
import '../../deck/providers/deck_provider.dart';
import '../../deck/widgets/deck_row.dart';
import '../../shared/widgets/adaptive_scaffold.dart';
import '../../shared/widgets/app_semantics.dart';
import '../../shared/widgets/section_widgets.dart';
import '../../stats/providers/stats_provider.dart';

import '../../l10n/app_localizations.dart';
class DeckListPage extends ConsumerWidget {
  const DeckListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = KarisReviewLocalizations.of(context)!;
    final decksAsync = ref.watch(deckListProvider);
    final isTablet = MediaQuery.sizeOf(context).width >= 600;
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
                        onPressed: () => _showDeckDialog(context, ref),
                      ),
                    ],
                  ),
                  SizedBox(height: 18),
                  SectionHeader(
                    title: l10n.deckListTitle,
                    trailing: decksAsync.maybeWhen(
                      data: (decks) => '${decks.length} 个牌组',
                      orElse: () => '',
                    ),
                  ),
                  SizedBox(height: 12),
                  decksAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (error, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Text(
          l10n.errorLoadFailed,
                            style: TextStyle(color: KarisColors.cinnabar),
                          ),
                          SizedBox(height: 10),
                          TextButton(
                            onPressed: () =>
                                ref.read(deckListProvider.notifier).loadDecks(),
                            child: Text(l10n.errorRetry),
                          ),
                        ],
                      ),
                    ),
                    data: (decks) => decks.isEmpty
                        ? EmptyState(
                            icon: Icons.layers_outlined,
                            title: l10n.homeNoDecksTitle,
                            message: l10n.homeNoDecksMessage,
                            action: FilledButton.icon(
                              onPressed: () => _showDeckDialog(context, ref),
                              icon: const Icon(Icons.add, size: 17),
                              label: Text(l10n.deckCreateButton),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: decks.length,
                            separatorBuilder: (_, _) =>
                                SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final deck = decks[index];
                              return DeckRow(
                                name: deck.name,
                                cardCount: deck.cardCount,
                                dueCount: deck.dueCount,
                                newCount: deck.newCount,
                                stageDistribution: deck.stageDistribution,
                                onTap: () =>
                                    context.push('/decks/${deck.id}/cards'),
                                onEdit: () =>
                                    _showDeckDialog(context, ref, deck: deck),
                                onDelete: () =>
                                    _confirmDeleteDeck(context, ref, deck),
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

  void _showDeckDialog(BuildContext context, WidgetRef ref, {Deck? deck}) {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorSaveFailed)));
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
  final l10n = KarisReviewLocalizations.of(context)!;
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.deckDeleteTitle),
        content: Text('确定要删除“${deck.name}”吗？牌组内的所有卡片和复习记录也会删除。'),
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
