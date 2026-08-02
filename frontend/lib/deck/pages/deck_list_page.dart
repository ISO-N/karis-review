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

class DeckListPage extends ConsumerWidget {
  const DeckListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                            const SizedBox(height: 7),
                            KarisHeading(
                              child: Text(
                                '牌组',
                                style: karisDisplay(fontSize: 27),
                              ),
                            ),
                          ],
                        ),
                      ),
                      KarisIconButton(
                        icon: Icons.add,
                        tooltip: '新建牌组',
                        onPressed: () => _showDeckDialog(context, ref),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SectionHeader(
                    title: '全部牌组',
                    trailing: decksAsync.maybeWhen(
                      data: (decks) => '${decks.length} 个牌组',
                      orElse: () => '',
                    ),
                  ),
                  const SizedBox(height: 12),
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
                          const Text(
                            '加载失败，请检查网络后重试',
                            style: TextStyle(color: KarisColors.cinnabar),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () =>
                                ref.read(deckListProvider.notifier).loadDecks(),
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    ),
                    data: (decks) => decks.isEmpty
                        ? EmptyState(
                            icon: Icons.layers_outlined,
                            title: '还没有牌组',
                            message: '创建第一个牌组，开始记录你的复习队列',
                            action: FilledButton.icon(
                              onPressed: () => _showDeckDialog(context, ref),
                              icon: const Icon(Icons.add, size: 17),
                              label: const Text('创建牌组'),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: decks.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
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
      ).showSnackBar(const SnackBar(content: Text('保存失败，请检查网络后重试')));
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: KarisHeading(child: Text(widget.deck == null ? '新建牌组' : '重命名牌组')),
      content: TextField(
        controller: _controller,
        autofocus: shouldAutoFocus(context),
        autofillHints: const [AutofillHints.name],
        maxLength: 100,
        decoration: const InputDecoration(
          labelText: '牌组名称',
          hintText: '例如：日语 N5',
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
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.deck == null ? '创建' : '保存'),
        ),
      ],
    );
  }
}

void _confirmDeleteDeck(BuildContext context, WidgetRef ref, Deck deck) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('删除牌组'),
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
            onPressed: () {
              ref.read(deckListProvider.notifier).deleteDeck(deck.id);
              Navigator.pop(dialogContext);
            },
            child: const Text('删除'),
          ),
        ],
      );
    },
  );
}
