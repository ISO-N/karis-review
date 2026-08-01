import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/rich_card_content.dart';
import '../providers/review_provider.dart';

class ReviewPage extends ConsumerStatefulWidget {
  final String? filter;

  const ReviewPage({super.key, this.filter});

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final deckId = GoRouterState.of(context).uri.queryParameters['deck_id'];
      if (widget.filter == 'new') {
        ref.read(reviewProvider.notifier).loadNewCards(deckId: deckId);
      } else {
        ref.read(reviewProvider.notifier).loadDueCards(deckId: deckId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reviewState = ref.watch(reviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.filter == 'new' ? '学习模式' : '复习模式'),
        actions: [
          if (reviewState.totalCount > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${reviewState.reviewedCount}/${reviewState.totalCount}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(context, reviewState),
    );
  }

  Widget _buildBody(BuildContext context, ReviewSessionState state) {
    if (state.isLoading) {
      return const LoadingWidget(message: '加载卡片中...');
    }

    if (state.error != null) {
      return AppErrorWidget(
        message: state.error!,
        onRetry: () => widget.filter == 'new'
            ? ref.read(reviewProvider.notifier).loadNewCards()
            : ref.read(reviewProvider.notifier).loadDueCards(),
      );
    }

    if (state.isComplete) {
      return _buildCompleteView(context);
    }

    final card = state.currentCard;
    if (card == null || state.cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            const Text('暂无待复习的卡片',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('当前没有需要复习的卡片',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/decks'),
              child: const Text('返回牌组'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progress
          LinearProgressIndicator(
            value: state.totalCount > 0
                ? state.reviewedCount / state.totalCount
                : 0,
          ),
          const SizedBox(height: 16),

          // Card content
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!state.isFlipped) {
                  ref.read(reviewProvider.notifier).flip();
                }
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (child, animation) {
                  return RotationYTransition(
                    turns: animation,
                    child: child,
                  );
                },
                child: state.isFlipped
                    ? _buildCardBack(context, card.back ?? '', card)
                    : _buildCardFront(context, card.front, card),
              ),
            ),
          ),

          // Rating buttons (shown after flip)
          if (state.isFlipped) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _RatingButton(
                    label: '忘记',
                    icon: Icons.close,
                    color: Colors.red,
                    onTap: () => ref.read(reviewProvider.notifier).rate('FORGET'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RatingButton(
                    label: '模糊',
                    icon: Icons.help,
                    color: Colors.orange,
                    onTap: () => ref.read(reviewProvider.notifier).rate('VAGUE'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RatingButton(
                    label: '熟悉',
                    icon: Icons.check,
                    color: Colors.green,
                    onTap: () => ref.read(reviewProvider.notifier).rate('FAMILIAR'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildCardFront(BuildContext context, String content, dynamic card) {
    return Card(
      key: const ValueKey('front'),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help_outline, size: 32,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            SingleChildScrollView(
              child: RichCardContent(
                content: content,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),
            Text('点击卡片翻面',
                style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack(BuildContext context, String content, dynamic card) {
    return Card(
      key: const ValueKey('back'),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline, size: 32,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: RichCardContent(
                  content: content,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            if (card.learningMode) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '连续熟悉: ${card.consecutiveFamiliar}',
                  style: const TextStyle(color: Colors.orange, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.celebration, size: 80,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          const Text('复习完成！',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('太棒了，继续保持！',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.go('/decks'),
            child: const Text('返回牌组'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              ref.read(reviewProvider.notifier).reset();
              if (widget.filter == 'new') {
                ref.read(reviewProvider.notifier).loadNewCards();
              } else {
                ref.read(reviewProvider.notifier).loadDueCards();
              }
            },
            child: const Text('继续复习'),
          ),
        ],
      ),
    );
  }
}

class RotationYTransition extends StatelessWidget {
  final Animation<double> turns;
  final Widget child;

  const RotationYTransition({
    super.key,
    required this.turns,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: turns,
      builder: (context, child) {
        final angle = turns.value * 3.14159;
        final isVisible = angle < 1.57; // 90 degrees
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: isVisible ? child : Opacity(
            opacity: 0,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RatingButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withValues(alpha: 0.3)),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}