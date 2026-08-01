import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_widget.dart';
import '../providers/deck_provider.dart';


class DeckListPage extends ConsumerWidget {
  const DeckListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(deckListProvider);


    return Scaffold(
      appBar: AppBar(
        title: const Text('我的牌组'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.go('/stats'),
            tooltip: '统计',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
            tooltip: '设置',
          ),
        ],
      ),
      body: decksAsync.when(
        loading: () => const LoadingWidget(message: '加载牌组中...'),
        error: (e, _) => AppErrorWidget(
          message: '加载失败: $e',
          onRetry: () => ref.read(deckListProvider.notifier).loadDecks(),
        ),
        data: (decks) {
          if (decks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 64,
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('还没有牌组',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('点击下方按钮创建第一个牌组',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(deckListProvider.notifier).loadDecks(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: decks.length,
              itemBuilder: (context, index) {
                final deck = decks[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Slidable(
                    endActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (_) => _showEditDialog(context, ref, deck),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          icon: Icons.edit,
                          label: '重命名',
                        ),
                        SlidableAction(
                          onPressed: (_) => _showDeleteDialog(context, ref, deck),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: '删除',
                        ),
                      ],
                    ),
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text('${deck.cardCount}',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer)),
                        ),
                        title: Text(deck.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${deck.dueCount} 张待复习 · 共 ${deck.cardCount} 张卡片'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (deck.dueCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('${deck.dueCount}',
                                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                              ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () => context.go('/decks/${deck.id}/cards'),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('新建牌组'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.book), label: '牌组'),
          BottomNavigationBarItem(icon: Icon(Icons.replay), label: '复习'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '统计'),
        ],
        onTap: (index) {
          switch (index) {
            case 0: break;
            case 1: context.go('/review');
            case 2: context.go('/stats');
          }
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建牌组'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '牌组名称', hintText: '例如：日语N5'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(deckListProvider.notifier).createDeck(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, dynamic deck) {
    final controller = TextEditingController(text: deck.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名牌组'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '牌组名称'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(deckListProvider.notifier).updateDeck(deck.id, controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, dynamic deck) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除牌组'),
        content: Text('确定要删除"${deck.name}"吗？牌组内的所有卡片也将被删除。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(deckListProvider.notifier).deleteDeck(deck.id);
              Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}