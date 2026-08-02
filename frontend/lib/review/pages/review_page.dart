import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/widgets/adaptive_scaffold.dart';
import '../../shared/utils/motion.dart';
import '../../shared/widgets/app_semantics.dart';
import '../../shared/widgets/rich_card_content.dart';
import '../../shared/widgets/section_widgets.dart';
import '../../shared/widgets/stage_ruler.dart';
import '../models/review_card.dart';
import '../providers/review_provider.dart';
import '../widgets/review_flip_card.dart';

class ReviewPage extends ConsumerStatefulWidget {
  const ReviewPage({super.key});

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final query = GoRouterState.of(context).uri.queryParameters;
      final mode = query['mode'] == 'new' ? 'new' : 'due';
      final deckId = query['deck_id'];
      ref
          .read(reviewProvider.notifier)
          .loadQueue(
            mode: mode,
            deckId: deckId == 'all' || deckId == null ? null : deckId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewProvider);
    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    final title = state.mode == 'new' ? '学习模式' : '复习模式';

    return Scaffold(
      backgroundColor: KarisColors.paper,
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : state.error != null && !state.ratingFailed
            ? EmptyState(
                icon: Icons.error_outline,
                title: '队列加载失败',
                message: state.error!,
                action: FilledButton.icon(
                  onPressed: () => _reload(state),
                  icon: const Icon(Icons.refresh, size: 17),
                  label: const Text('重试'),
                ),
              )
            : state.cards.isEmpty
            ? EmptyState(
                icon: Icons.check_circle_outline,
                title: state.mode == 'new' ? '暂时没有新卡' : '暂无待复习的卡片',
                message: state.mode == 'new'
                    ? '所有新卡都已经进入复习队列'
                    : '当前范围没有到期卡片，先休息一下',
                action: FilledButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home_outlined, size: 17),
                  label: const Text('返回今日'),
                ),
              )
            : state.isComplete
            ? _CompleteView(state: state)
            : _buildSession(context, state, isTablet, title),
      ),
    );
  }

  Widget _buildSession(
    BuildContext context,
    ReviewSessionState state,
    bool isTablet,
    String title,
  ) {
    final card = state.currentCard!;
    if (isTablet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _QueuePanel(state: state),
          const SizedBox(width: 0),
          Expanded(
            child: _ReviewStage(
              state: state,
              card: card,
              title: title,
              onRate: (rating) => _rate(rating),
            ),
          ),
        ],
      );
    }
    return _ReviewStage(
      state: state,
      card: card,
      title: title,
      onRate: (rating) => _rate(rating),
    );
  }

  Future<void> _rate(String rating) async {
    final result = await ref.read(reviewProvider.notifier).rate(rating);
    if (result == null) {
      if (mounted) {
        announceMessage(context, '评分失败，请检查网络后重试');
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('评分失败，请检查网络后重试')));
      }
      return;
    }
    if (!mounted) return;
    final label = switch (rating) {
      'FORGET' => '忘记',
      'VAGUE' => '模糊',
      'FAMILIAR' => '熟悉',
      _ => rating,
    };
    final interval = result.nextIntervalDays > 0
        ? KarisTheme.intervalLabel(result.nextIntervalDays)
        : (rating == 'FAMILIAR' && result.learningMode ? '继续' : '重学');
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final message = '已评分：$label · 下次 $interval';
    announceMessage(context, message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _reload(ReviewSessionState state) {
    ref
        .read(reviewProvider.notifier)
        .loadQueue(mode: state.mode, deckId: state.deckId);
  }
}

class _ReviewStage extends ConsumerWidget {
  final ReviewSessionState state;
  final ReviewCard card;
  final String title;
  final ValueChanged<String> onRate;

  const _ReviewStage({
    required this.state,
    required this.card,
    required this.title,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    final current = state.currentIndex + 1;
    final total = state.totalCount;
    final progress = total == 0 ? 0.0 : current / total;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, isTablet ? 18 : 12),
            child: Center(
              child: SizedBox(
                width: double.infinity,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          KarisIconButton(
                            icon: Icons.arrow_back,
                            tooltip: '返回',
                            onPressed: () => context.go('/home'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Kicker('队列'),
                                const SizedBox(height: 4),
                                KarisHeading(
                                  child: Text(
                                    title,
                                    style: karisDisplay(fontSize: 25),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '$current / $total',
                            style: karisMono(
                              fontSize: 12,
                              color: KarisColors.stone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 5,
                                backgroundColor: KarisColors.hairline,
                                valueColor: const AlwaysStoppedAnimation(
                                  KarisColors.jade,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$current / $total',
                            style: karisMono(
                              fontSize: 10,
                              color: KarisColors.stone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isTablet ? 560 : 520,
                            ),
                            child: AnimatedSwitcher(
                              duration: reducedDuration(
                                context,
                                const Duration(milliseconds: 240),
                              ),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeIn,
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.025),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: ReviewFlipCard(
                                key: ValueKey(
                                  '${state.currentIndex}-${card.id}',
                                ),
                                flipped: state.isFlipped,
                                semanticsLabel: state.isFlipped
                                    ? '闪卡，点击回到问题面'
                                    : '闪卡，点击翻面',
                                onTap: () {
                                  ref.read(reviewProvider.notifier).flip();
                                },
                                front: _CardFace(
                                  key: const ValueKey('front'),
                                  child: _FrontFace(
                                    card: card,
                                    current: current,
                                    total: total,
                                  ),
                                ),
                                back: _CardFace(
                                  key: const ValueKey('back'),
                                  child: _BackFace(card: card),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (isTablet)
          _TabletRatingArea(state: state, card: card, onRate: onRate)
        else
          _MobileRatingArea(state: state, card: card, onRate: onRate),
      ],
    );
  }
}

class _TabletRatingArea extends StatelessWidget {
  final ReviewSessionState state;
  final ReviewCard card;
  final ValueChanged<String> onRate;

  const _TabletRatingArea({
    required this.state,
    required this.card,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    if (!state.isFlipped) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '本次回忆',
                style: TextStyle(
                  color: KarisColors.stone,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 9),
              _RatingRow(card: card, onRate: onRate),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileRatingArea extends StatelessWidget {
  final ReviewSessionState state;
  final ReviewCard card;
  final ValueChanged<String> onRate;

  const _MobileRatingArea({
    required this.state,
    required this.card,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: KarisColors.surface.withValues(alpha: 0.96),
          border: const Border(top: BorderSide(color: KarisColors.hairline)),
        ),
        child: state.isFlipped
            ? _RatingRow(card: card, onRate: onRate)
            : const Center(
                child: Text(
                  '点按翻面',
                  style: TextStyle(
                    color: KarisColors.stone,
                    fontFamily: KarisTheme.monoFamily,
                    fontSize: 10,
                    letterSpacing: 0,
                  ),
                ),
              ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final ReviewCard card;
  final ValueChanged<String> onRate;

  const _RatingRow({required this.card, required this.onRate});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RatingButton(
            label: '忘记',
            sub: '重学',
            icon: Icons.close,
            color: KarisColors.cinnabar,
            onTap: () => onRate('FORGET'),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _RatingButton(
            label: '模糊',
            sub: card.vagueIntervalDays > 0
                ? KarisTheme.intervalLabel(card.vagueIntervalDays)
                : '重学',
            icon: Icons.help_outline,
            color: KarisColors.amber,
            onTap: () => onRate('VAGUE'),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _RatingButton(
            label: '熟悉',
            sub: card.learningMode && card.familiarIntervalDays == 0
                ? '继续'
                : KarisTheme.intervalLabel(card.familiarIntervalDays),
            icon: Icons.check,
            color: KarisColors.jade,
            onTap: () => onRate('FAMILIAR'),
          ),
        ),
      ],
    );
  }
}

class _QueuePanel extends StatelessWidget {
  final ReviewSessionState state;

  const _QueuePanel({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 246,
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
      decoration: BoxDecoration(
        color: KarisColors.surface.withValues(alpha: 0.72),
        border: const Border(right: BorderSide(color: KarisColors.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KarisHeading(
            child: Text(
              '今日队列',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: state.cards.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final card = state.cards[index];
                final active = index == state.currentIndex;
                return Container(
                  margin: active
                      ? const EdgeInsets.symmetric(horizontal: 8)
                      : null,
                  padding: const EdgeInsets.all(10),
                  decoration: active
                      ? BoxDecoration(
                          color: KarisColors.surface,
                          border: Border.all(color: KarisColors.jade),
                          borderRadius: BorderRadius.circular(8),
                        )
                      : null,
                  child: Row(
                    children: [
                      Text(
                        (index + 1).toString().padLeft(2, '0'),
                        style: karisMono(
                          fontSize: 10,
                          color: active ? KarisColors.jade : KarisColors.stone,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _plainFront(card.front),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: active ? KarisColors.ink : KarisColors.stone,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.w400,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _plainFront(String content) {
    final line = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    return line.isEmpty ? '卡片' : line;
  }
}

class _CardFace extends StatelessWidget {
  final Widget child;

  const _CardFace({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ReviewCardFrame(child: child);
  }
}

class _FrontFace extends StatelessWidget {
  final ReviewCard card;
  final int current;
  final int total;

  const _FrontFace({
    required this.card,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return _CenteredCardContent(
      header: Row(
        children: [
          Text(
            '$current / $total',
            style: karisMono(fontSize: 10, color: KarisColors.stone),
          ),
          const Spacer(),
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: KarisColors.jadeSoft,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Stage ${card.stage} · ${KarisTheme.stageName(card.stage)}',
              style: karisMono(
                fontSize: 10,
                color: KarisColors.jade,
                weight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      footer: const Text(
        '点按翻面',
        style: TextStyle(
          color: KarisColors.stone,
          fontFamily: KarisTheme.monoFamily,
          fontSize: 10,
          letterSpacing: 0,
        ),
      ),
      child: RichCardContent(
        content: card.front,
        textAlign: TextAlign.center,
        style: karisDisplay(fontSize: 28),
      ),
    );
  }
}

class _BackFace extends StatelessWidget {
  final ReviewCard card;

  const _BackFace({required this.card});

  @override
  Widget build(BuildContext context) {
    return _CenteredCardContent(
      header: Row(
        children: [
          const Text(
            '答案',
            style: TextStyle(
              color: KarisColors.stone,
              fontFamily: KarisTheme.monoFamily,
              fontSize: 10,
              letterSpacing: 0,
            ),
          ),
          const Spacer(),
          if (card.learningMode)
            Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: KarisColors.amberSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '重学中 · ${card.consecutiveFamiliar}/${card.learningGoal}',
                style: const TextStyle(
                  color: KarisColors.amber,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
        ],
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  '当前间隔 ${card.currentIntervalDays == 0 ? '新卡' : KarisTheme.intervalLabel(card.currentIntervalDays)}',
                  style: const TextStyle(
                    color: KarisColors.stone,
                    fontSize: 12,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  card.learningMode && card.familiarIntervalDays == 0
                      ? '继续熟悉可脱离'
                      : '熟悉后 ${KarisTheme.intervalLabel(card.familiarIntervalDays)}',
                  style: const TextStyle(
                    color: KarisColors.jade,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StageRuler(
            compact: true,
            currentStage: card.stage,
            distribution: List.filled(9, 0),
          ),
          const SizedBox(height: 6),
          const Text(
            '点按回到问题面',
            style: TextStyle(
              color: KarisColors.stone,
              fontFamily: KarisTheme.monoFamily,
              fontSize: 10,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
      child: RichCardContent(
        content: card.back ?? '',
        textAlign: TextAlign.center,
        style: karisDisplay(fontSize: 28),
      ),
    );
  }
}

class _CenteredCardContent extends StatelessWidget {
  final Widget child;
  final Widget? header;
  final Widget? footer;

  const _CenteredCardContent({required this.child, this.header, this.footer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
      child: Column(
        children: [
          if (header != null) ...[header!, const SizedBox(height: 10)],
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: child,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (footer != null) ...[const SizedBox(height: 10), footer!],
        ],
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final String sub;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RatingButton({
    required this.label,
    required this.sub,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return KarisInteractive(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 74),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: KarisColors.surface,
            border: Border.all(color: color.withValues(alpha: 0.38)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              Text(
                sub,
                style: karisMono(
                  fontSize: 10,
                  color: color.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompleteView extends ConsumerWidget {
  final ReviewSessionState state;

  const _CompleteView({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: KarisColors.jade,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check,
                color: KarisColors.surface,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            KarisHeading(
              child: Text(
                state.mode == 'new' ? '本轮学习完成' : '今日复习完成',
                style: karisDisplay(fontSize: 28),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '本次 ${state.totalCount} 张 · 已复习 ${state.reviewedCount}',
              style: const TextStyle(
                color: KarisColors.stone,
                fontSize: 13,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    ref
                        .read(reviewProvider.notifier)
                        .loadQueue(mode: state.mode, deckId: state.deckId);
                  },
                  icon: const Icon(Icons.refresh, size: 17),
                  label: const Text('再来一轮'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home_outlined, size: 17),
                  label: const Text('返回今日'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
