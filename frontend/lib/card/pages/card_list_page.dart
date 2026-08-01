import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/rich_card_content.dart';
import '../providers/card_provider.dart';
import '../../deck/providers/deck_provider.dart';
import '../../shared/utils/date_utils.dart';

class CardListPage extends ConsumerWidget {
  final String deckId;

  const CardListPage({super.key, required this.deckId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(cardListProvider(deckId));
    final decksAsync = ref.watch(deckListProvider);

    // Get deck name from data
    final name = decksAsync.maybeWhen(
      orElse: () => '卡片',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.go('/decks/$deckId/stats'),
            tooltip: '进度',
          ),
          IconButton(
            icon: const Icon(Icons.replay),
            onPressed: () => context.go('/review/due?deck_id=$deckId'),
            tooltip: '复习',
          ),
        ],
      ),
      body: cardsAsync.when(
        loading: () => const LoadingWidget(message: '加载卡片中...'),
        error: (e, _) => AppErrorWidget(
          message: '加载失败: $e',
          onRetry: () => ref.read(cardListProvider(deckId).notifier).loadCards(),
        ),
        data: (cards) {
          if (cards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.credit_card, size: 64,
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text('还没有卡片', style: TextStyle(color: Colors.grey, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('点击下方按钮创建第一张卡片',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(cardListProvider(deckId).notifier).loadCards(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                final stageNames = ['学习中', '1天', '2天', '4天', '7天', '15天', '30天', '90天', '180天'];
                final stageName = card.stage >= 0 && card.stage < stageNames.length
                    ? stageNames[card.stage]
                    : 'Stage ${card.stage}';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Slidable(
                    endActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (_) => context.push('/decks/$deckId/cards/${card.id}/edit'),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          icon: Icons.edit,
                          label: '编辑',
                        ),
                        SlidableAction(
                          onPressed: (_) => _showDeleteDialog(context, ref, card),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: '删除',
                        ),
                      ],
                    ),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: card.stage <= 2
                                        ? Colors.blue.withValues(alpha: 0.1)
                                        : Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(stageName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: card.stage <= 2 ? Colors.blue : Colors.green,
                                      )),
                                ),
                                if (card.learningMode)
                                  Container(
                                    margin: const EdgeInsets.only(left: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('重学',
                                        style: TextStyle(fontSize: 12, color: Colors.orange)),
                                  ),
                                const Spacer(),
                                if (card.nextReviewDate != null)
                                  Text(AppDateUtils.relativeDate(DateTime.parse(card.nextReviewDate!)),
                                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            RichCardContent(
                                content: card.front,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                maxLines: 2),
                            const SizedBox(height: 4),
                            RichCardContent(
                                content: card.back,
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                maxLines: 2),
                          ],
                        ),
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
        onPressed: () => context.push('/decks/$deckId/cards/create'),
        icon: const Icon(Icons.add),
        label: const Text('新建卡片'),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, dynamic card) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除卡片'),
        content: const Text('确定要删除这张卡片吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(cardListProvider(deckId).notifier).deleteCard(card.id);
              Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}