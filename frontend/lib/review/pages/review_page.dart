import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/widgets/adaptive_scaffold.dart';
import '../../shared/utils/motion.dart';
import '../../shared/widgets/app_semantics.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/loading_widget.dart';
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
      backgroundColor: context.karisColors.paper,
      body: SafeArea(
        child: state.isLoading
            ? const LoadingWidget()
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
      if (mounted) announceMessage(context, '评分失败，请检查网络后重试');
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
    announceMessage(context, '已评分：$label · 下次 $interval');
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
    final colors = context.karisColors;
    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    final current = state.currentIndex + 1;
    final total = state.sessionTotal;
    final progress = total == 0 ? 0.0 : current / total;

    // 键盘快捷键：空格翻面、1/2/3 评分（仅翻面后可评）。
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }
        if (event.logicalKey == LogicalKeyboardKey.space) {
          ref.read(reviewProvider.notifier).flip();
          return KeyEventResult.handled;
        }
        final rating = switch (event.logicalKey) {
          LogicalKeyboardKey.digit1 => 'FORGET',
          LogicalKeyboardKey.digit2 => 'VAGUE',
          LogicalKeyboardKey.digit3 => 'FAMILIAR',
          _ => null,
        };
        if (rating != null) {
          if (state.isFlipped && !state.isRating) onRate(rating);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Column(
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
                          _StatusChip(state: state),
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
                                backgroundColor: colors.hairline,
                                valueColor: AlwaysStoppedAnimation(
                                  colors.jade,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$current / $total',
                            style: karisMono(
                              fontSize: 10,
                              color: colors.stone,
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
          _RatingArea(
            state: state,
            card: card,
            onRate: onRate,
            maxWidth: 620,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          )
        else
          _RatingArea(
            state: state,
            card: card,
            onRate: onRate,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends ConsumerWidget {
  final ReviewSessionState state;

  const _StatusChip({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spec = _specFor(context, state);
    if (spec == null) {
      // 固定占位，防止信息出现时布局跳动。
      return const SizedBox(width: 20, height: 24);
    }
    return SizedBox(
      height: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: spec.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: spec.color.withValues(alpha: 0.25)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: Row(
            key: ValueKey('${spec.icon.codePoint}-${spec.text}'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(spec.icon, size: 12, color: spec.color),
              const SizedBox(width: 4),
              Text(
                spec.text,
                style: TextStyle(
                  fontFamily: KarisTheme.monoFamily,
                  fontSize: 10,
                  color: spec.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _StatusSpec? _specFor(BuildContext context, ReviewSessionState state) {
    final colors = context.karisColors;
    if (state.ratingFailed) {
      return _StatusSpec(
        icon: Icons.error_outline,
        text: '评分失败',
        color: colors.cinnabar,
      );
    }
    final result = state.lastResult;
    if (result != null) {
      final label = switch (result.rating) {
        'FORGET' => '忘记',
        'VAGUE' => '模糊',
        'FAMILIAR' => '熟悉',
        _ => result.rating,
      };
      final interval = result.nextIntervalDays > 0
          ? KarisTheme.intervalLabel(result.nextIntervalDays)
          : (result.rating == 'FAMILIAR' && result.learningMode ? '继续' : '重学');
      return _StatusSpec(
        icon: Icons.check,
        text: '已评分 $label · 下次 $interval',
        color: colors.jade,
      );
    }
    if (state.loadingMore) {
      return _StatusSpec(
        icon: Icons.sync,
        text: '加载更多队列',
        color: colors.amber,
      );
    }
    if (state.pendingSyncCount > 0) {
      return _StatusSpec(
        icon: Icons.cloud_off_outlined,
        text: '离线 · ${state.pendingSyncCount} 条待同步',
        color: colors.amber,
      );
    }
    return null;
  }
}

class _StatusSpec {
  final IconData icon;
  final String text;
  final Color color;

  const _StatusSpec({
    required this.icon,
    required this.text,
    required this.color,
  });
}

class _RatingArea extends StatelessWidget {
  final ReviewSessionState state;
  final ReviewCard card;
  final ValueChanged<String> onRate;
  final double? maxWidth;
  final EdgeInsetsGeometry padding;

  const _RatingArea({
    required this.state,
    required this.card,
    required this.onRate,
    this.maxWidth,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // 翻面后立即解锁评分按钮；loadingMore 只是后台队列预加载，
    // 与评分可用性无关（loadMore 仅向队尾追加，不移动 currentIndex）。
    final colors = context.karisColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = state.isFlipped && !state.isRating;
    return Padding(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth ?? 520),
          child: Container(
            height: 76,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.78),
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark
                          ? const Color(0xFF000000)
                          : const Color(0xFF161F1B))
                      .withValues(alpha: isDark ? 0.45 : 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: const Alignment(0, 0.2),
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.06 : 0.28),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
            child: _RatingRow(
              card: card,
              onRate: onRate,
              enabled: enabled,
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
  final bool enabled;

  const _RatingRow({
    required this.card,
    required this.onRate,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    return Row(
      children: [
        Expanded(
          child: _RatingButton(
            label: '忘记',
            sub: '重学',
            shortcut: '1',
            icon: Icons.close,
            color: colors.cinnabar,
            enabled: enabled,
            onTap: () => onRate('FORGET'),
          ),
        ),
        _divider(colors),
        Expanded(
          child: _RatingButton(
            label: '模糊',
            sub: card.vagueIntervalDays > 0
                ? KarisTheme.intervalLabel(card.vagueIntervalDays)
                : '重学',
            shortcut: '2',
            icon: Icons.help_outline,
            color: colors.amber,
            enabled: enabled,
            onTap: () => onRate('VAGUE'),
          ),
        ),
        _divider(colors),
        Expanded(
          child: _RatingButton(
            label: '熟悉',
            sub: card.learningMode && card.familiarIntervalDays == 0
                ? '继续'
                : KarisTheme.intervalLabel(card.familiarIntervalDays),
            shortcut: '3',
            icon: Icons.check,
            color: colors.jade,
            enabled: enabled,
            onTap: () => onRate('FAMILIAR'),
          ),
        ),
      ],
    );
  }

  Widget _divider(KarisColors colors) {
    return Container(
      width: 1,
      height: 40,
      color: colors.hairline,
    );
  }
}

class _QueuePanel extends StatelessWidget {
  final ReviewSessionState state;

  const _QueuePanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    return Container(
      width: 246,
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.72),
        border: Border(right: BorderSide(color: colors.hairline)),
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
                          color: colors.surface,
                          border: Border.all(color: colors.jade),
                          borderRadius: BorderRadius.circular(8),
                        )
                      : null,
                  child: Row(
                    children: [
                      Text(
                        (index + 1).toString().padLeft(2, '0'),
                        style: karisMono(
                          fontSize: 10,
                          color: active ? colors.jade : colors.stone,
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
                            color: active ? colors.ink : colors.stone,
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
    final colors = context.karisColors;
    return _CenteredCardContent(
      header: Row(
        children: [
          Text(
            '$current / $total',
            style: karisMono(fontSize: 10, color: colors.stone),
          ),
          const Spacer(),
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.jadeSoft,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Stage ${card.stage} · ${KarisTheme.stageName(card.stage)}',
              style: karisMono(
                fontSize: 10,
                color: colors.jade,
                weight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      footer: Text(
        '点按或按空格翻面',
        style: TextStyle(
          color: colors.stone,
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
    final colors = context.karisColors;
    return _CenteredCardContent(
      header: Row(
        children: [
          Text(
            '答案',
            style: TextStyle(
              color: colors.stone,
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
                color: colors.amberSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '重学中 · ${card.consecutiveFamiliar}/${card.learningGoal}',
                style: TextStyle(
                  color: colors.amber,
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
                  style: TextStyle(
                    color: colors.stone,
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
                  style: TextStyle(
                    color: colors.jade,
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
          Text(
            '点按回到问题面',
            style: TextStyle(
              color: colors.stone,
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
  final String shortcut;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _RatingButton({
    required this.label,
    required this.sub,
    required this.shortcut,
    required this.icon,
    required this.color,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    final foreground =
        enabled ? color : colors.stone.withValues(alpha: 0.55);
    return Semantics(
      button: true,
      enabled: enabled,
      label: '$label，快捷键 $shortcut',
      child: KarisInteractive(
        child: KarisPressable(
          onTap: enabled ? onTap : null,
          pressedScale: 0.94,
          child: SizedBox(
            height: 62,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: foreground, size: 17),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      shortcut,
                      style: karisMono(
                        fontSize: 8,
                        color: foreground.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                Text(
                  sub,
                  style: karisMono(
                    fontSize: 9,
                    color: enabled
                        ? color.withValues(alpha: 0.75)
                        : colors.stone.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
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
    final colors = context.karisColors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: KarisEntrance(
          duration: KarisMotion.grow,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 完成图标：弹性放大收尾，克制不浮夸。
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1),
                duration: reducedDuration(context, KarisMotion.grow),
                curve: KarisMotion.springy,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: colors.jade,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.check,
                    color: colors.surface,
                    size: 26,
                  ),
                ),
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
              ),
              const SizedBox(height: 16),
              KarisHeading(
                child: Text(
                  state.mode == 'new' ? '本轮学习完成' : '今日复习完成',
                  style: karisDisplay(fontSize: 28, color: colors.ink),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.mode == 'new'
                    ? '本次 ${state.sessionTotal} 张 · 已学习 ${state.reviewedCount}'
                    : '本次 ${state.sessionTotal} 张 · 已复习 ${state.reviewedCount}',
                style: TextStyle(
                  color: colors.stone,
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
      ),
    );
  }
}
