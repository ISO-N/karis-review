import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../deck/models/deck.dart';
import '../../deck/providers/deck_provider.dart';
import '../../deck/widgets/deck_row.dart';
import '../../shared/widgets/adaptive_scaffold.dart';
import '../../shared/widgets/section_widgets.dart';

class DeckListPage extends ConsumerWidget {
  const DeckListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(deckListProvider);

    return AdaptiveAppScaffold(
      current: KarisNavItem.decks,
      onSelect: (item) => _go(item, context),
      body: RefreshIndicator(
        onRefresh: () => ref.read(deckListProvider.notifier).loadDecks(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
                            Text('牌组', style: karisDisplay(fontSize: 27)),
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
                            '加载失败',
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
                        : Column(
                            children: [
                              for (var i = 0; i < decks.length; i++) ...[
                                DeckRow(
                                  name: decks[i].name,
                                  cardCount: decks[i].cardCount,
                                  dueCount: decks[i].dueCount,
                                  newCount: decks[i].newCount,
                                  stageDistribution: decks[i].stageDistribution,
                                  onTap: () => context.push(
                                    '/decks/${decks[i].id}/cards',
                                  ),
                                  onEdit: () => _showDeckDialog(
                                    context,
                                    ref,
                                    deck: decks[i],
                                  ),
                                  onDelete: () => _confirmDeleteDeck(
                                    context,
                                    ref,
                                    decks[i],
                                  ),
                                ),
                                if (i < decks.length - 1)
                                  const SizedBox(height: 10),
                              ],
                            ],
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
    final controller = TextEditingController(text: deck?.name ?? '');
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(deck == null ? '新建牌组' : '重命名牌组'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: '牌组名称',
              hintText: '例如：日语 N5',
            ),
            onSubmitted: (_) => _saveDeck(dialogContext, ref, controller, deck),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => _saveDeck(dialogContext, ref, controller, deck),
              child: Text(deck == null ? '创建' : '保存'),
            ),
          ],
        );
      },
    );
  }

  void _saveDeck(
    BuildContext dialogContext,
    WidgetRef ref,
    TextEditingController controller,
    Deck? deck,
  ) {
    final name = controller.text.trim();
    if (name.isEmpty) return;
    final notifier = ref.read(deckListProvider.notifier);
    if (deck == null) {
      notifier.createDeck(name);
    } else {
      notifier.updateDeck(deck.id, name);
    }
    Navigator.pop(dialogContext);
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
}
