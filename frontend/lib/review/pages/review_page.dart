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
import '../../shared/widgets/memory_ring.dart';
import '../../shared/widgets/rich_card_content.dart';
import '../../shared/widgets/section_widgets.dart';
import '../../shared/widgets/stage_ruler.dart';
import '../../tts/tts_provider.dart';
import '../../tts/widgets/tts_button.dart';
import '../models/review_card.dart';
import '../providers/review_provider.dart';
import '../widgets/review_flip_card.dart';

class ReviewPage extends ConsumerStatefulWidget {
  const ReviewPage({super.key});

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage> {
  // 缓存的 TTS notifier：dispose 阶段 ref 不可用（element 已卸载），
  // 直接调用实例停止朗读，避免残留语音。
  TtsNotifier? _ttsNotifier;

  @override
  void initState() {
    super.initState();
    _ttsNotifier = ref.read(ttsProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 探测 TTS 引擎可用性并加载朗读偏好（幂等）。
      _ttsNotifier?.init();
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
  void dispose() {
    // 离开复习页停止朗读，防止后台残留语音。
    _ttsNotifier?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 只监听低频分支字段：isLoading / error / ratingFailed / cards 是否为空 / 是否完成。
    // 高频状态（isFlipped、isRating、lastResult、pendingSyncCount 等）由下方
    // 独立 ConsumerWidget 各自 select 监听，避免评分/翻面时整页重建。
    final mode = ref.watch(reviewProvider.select((s) => s.mode));
    final isLoading = ref.watch(reviewProvider.select((s) => s.isLoading));
    final error = ref.watch(reviewProvider.select((s) => s.error));
    final ratingFailed = ref.watch(reviewProvider.select((s) => s.ratingFailed));
    final cardsEmpty = ref.watch(reviewProvider.select((s) => s.cards.isEmpty));
    final isComplete = ref.watch(reviewProvider.select((s) => s.isComplete));
    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    final title = mode == 'new' ? '学习模式' : '复习模式';

    return Scaffold(
      backgroundColor: context.karisColors.paper,
      body: SafeArea(
        child: isLoading
            ? const LoadingWidget()
            : error != null && !ratingFailed
            ? EmptyState(
                icon: Icons.error_outline,
                title: '队列加载失败',
                message: error,
                action: FilledButton.icon(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh, size: 17),
                  label: const Text('重试'),
                ),
              )
            : cardsEmpty
            ? EmptyState(
                icon: Icons.check_circle_outline,
                title: mode == 'new' ? '暂时没有新卡' : '暂无待复习的卡片',
                message: mode == 'new'
                    ? '所有新卡都已经进入复习队列'
                    : '当前范围没有到期卡片，先休息一下',
                action: FilledButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home_outlined, size: 17),
                  label: const Text('返回今日'),
                ),
              )
            : isComplete
            ? const _CompleteView()
            : isTablet
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _QueuePanel(),
                  Expanded(
                    child: _ReviewStage(title: title, onRate: _rate),
                  ),
                ],
              )
            : _ReviewStage(title: title, onRate: _rate),
      ),
    );
  }

  Future<void> _rate(String rating) async {
    // 评分换卡：先停掉当前卡片的朗读，避免旧卡语音残留。
    await ref.read(ttsProvider.notifier).stop();
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

  void _reload() {
    final state = ref.read(reviewProvider);
    ref
        .read(reviewProvider.notifier)
        .loadQueue(mode: state.mode, deckId: state.deckId);
  }
}

class _ReviewStage extends ConsumerWidget {
  final String title;
  final ValueChanged<String> onRate;

  const _ReviewStage({
    required this.title,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.karisColors;
    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    // 进度条只依赖 currentIndex / sessionTotal：评分换卡时才重建本层骨架。
    final current = ref.watch(reviewProvider.select((s) => s.currentIndex + 1));
    final total = ref.watch(reviewProvider.select((s) => s.sessionTotal));
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
        // V：朗读当前显示的面（翻面读背面，未翻读正面）。
        if (event.logicalKey == LogicalKeyboardKey.keyV) {
          final s = ref.read(reviewProvider);
          final card = s.currentCard;
          if (card != null) {
            final isFlipped = s.isFlipped;
            ref.read(ttsProvider.notifier).toggle(
                  isFlipped ? 'back' : 'front',
                  isFlipped ? (card.back ?? '') : card.front,
                );
          }
          return KeyEventResult.handled;
        }
        final rating = switch (event.logicalKey) {
          LogicalKeyboardKey.digit1 => 'FORGET',
          LogicalKeyboardKey.digit2 => 'VAGUE',
          LogicalKeyboardKey.digit3 => 'FAMILIAR',
          _ => null,
        };
        if (rating != null) {
          // 事件回调中读取最新状态，避免为快捷键监听 isFlipped/isRating
          // 而让整个舞台随翻面重建。
          final isFlipped = ref.read(
            reviewProvider.select((s) => s.isFlipped),
          );
          final isRating = ref.read(
            reviewProvider.select((s) => s.isRating),
          );
          if (isFlipped && !isRating) onRate(rating);
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
                            const _StatusChip(),
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
                              child: const _FlipCardArea(),
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
              onRate: onRate,
              maxWidth: 620,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            )
          else
            _RatingArea(
              onRate: onRate,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            ),
        ],
      ),
    );
  }
}

/// 翻面卡片区：只监听 currentCard / currentIndex / isFlipped。
/// 翻面（isFlipped）变化时仅重建此子树，不波及进度条、评分区与队列面板。
class _FlipCardArea extends ConsumerWidget {
  const _FlipCardArea();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(reviewProvider.select((s) => s.currentCard));
    if (card == null) return const SizedBox.shrink();
    final current = ref.watch(reviewProvider.select((s) => s.currentIndex + 1));
    final total = ref.watch(reviewProvider.select((s) => s.sessionTotal));
    final isFlipped = ref.watch(reviewProvider.select((s) => s.isFlipped));
    // 只读上次评分的 rating 字段：决定换卡时旧卡向哪个方向离场。
    // 队列加载/追加时 lastResult 已被 clear，不会残留上一轮的方向。
    final lastRating = ref.watch(
      reviewProvider.select((s) => s.lastResult?.rating),
    );
    return AnimatedSwitcher(
      duration: reducedDuration(
        context,
        const Duration(milliseconds: 240),
      ),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        // 评分离场方向即语义（一次性微型叙事）：
        // FORGET 向左下方沉出（回落）、FAMILIAR 向右上方轻扬（生长）、
        // VAGUE 垂直淡出（悬置）。新卡仍从下方淡入，保持克制不抢戏。
        final isOutgoing = animation.status == AnimationStatus.reverse;
        final begin = isOutgoing
            ? Offset.zero
            : const Offset(0, 0.025);
        final end = isOutgoing ? _exitOffsetFor(lastRating) : Offset.zero;
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: begin, end: end).animate(animation),
            child: child,
          ),
        );
      },
      child: ReviewFlipCard(
        key: ValueKey('${current - 1}-${card.id}'),
        flipped: isFlipped,
        semanticsLabel: isFlipped ? '闪卡，点击回到问题面' : '闪卡，点击翻面',
        onTap: () {
          // 翻面切换朗读面：停掉当前朗读。
          ref.read(ttsProvider.notifier).stop();
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
          back: true,
          child: _BackFace(card: card),
        ),
      ),
    );
  }
}

class _StatusChip extends ConsumerWidget {
  const _StatusChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 只监听状态徽标相关字段：评分失败 / 上次评分结果 / 后台预加载 / 待同步数。
    // 其余状态变化（如翻面、进度）不会引发此处重建。
    final ratingFailed = ref.watch(
      reviewProvider.select((s) => s.ratingFailed),
    );
    final lastResult = ref.watch(reviewProvider.select((s) => s.lastResult));
    final loadingMore = ref.watch(
      reviewProvider.select((s) => s.loadingMore),
    );
    final pendingSyncCount = ref.watch(
      reviewProvider.select((s) => s.pendingSyncCount),
    );
    final spec = _specFor(
      context,
      ratingFailed: ratingFailed,
      lastResult: lastResult,
      loadingMore: loadingMore,
      pendingSyncCount: pendingSyncCount,
    );
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

  _StatusSpec? _specFor(
    BuildContext context, {
    required bool ratingFailed,
    required ReviewResult? lastResult,
    required bool loadingMore,
    required int pendingSyncCount,
  }) {
    final colors = context.karisColors;
    if (ratingFailed) {
      return _StatusSpec(
        icon: Icons.error_outline,
        text: '评分失败',
        color: colors.cinnabar,
      );
    }
    final result = lastResult;
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
    if (loadingMore) {
      return _StatusSpec(
        icon: Icons.sync,
        text: '加载更多队列',
        color: colors.amber,
      );
    }
    if (pendingSyncCount > 0) {
      return _StatusSpec(
        icon: Icons.cloud_off_outlined,
        text: '离线 · $pendingSyncCount 条待同步',
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

class _RatingArea extends ConsumerWidget {
  final ValueChanged<String> onRate;
  final double? maxWidth;
  final EdgeInsetsGeometry padding;

  const _RatingArea({
    required this.onRate,
    this.maxWidth,
    required this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 只监听翻面 / 评分中 / 当前卡片：评分按钮可用性变化时才重建此区域。
    final card = ref.watch(reviewProvider.select((s) => s.currentCard));
    final enabled = ref.watch(
      reviewProvider.select((s) => s.isFlipped && !s.isRating),
    );
    if (card == null) return const SizedBox.shrink();
    // 翻面后立即解锁评分按钮；loadingMore 只是后台队列预加载，
    // 与评分可用性无关（loadMore 仅向队尾追加，不移动 currentIndex）。
    final colors = context.karisColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

class _QueuePanel extends ConsumerWidget {
  const _QueuePanel();

  static final RegExp _spaceRegExp = RegExp(r'\s+');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.karisColors;
    // 只监听队列本身：loadMore 追加卡片 / currentIndex 移动时重建面板，
    // 评分过程中的其他状态变化（isFlipped、lastResult、pendingSyncCount 等）
    // 不再导致整个队列面板重建。
    final cards = ref.watch(reviewProvider.select((s) => s.cards));
    final currentIndex = ref.watch(
      reviewProvider.select((s) => s.currentIndex),
    );
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
              itemCount: cards.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final card = cards[index];
                final active = index == currentIndex;
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
    final line = content.replaceAll(_spaceRegExp, ' ').trim();
    return line.isEmpty ? '卡片' : line;
  }
}

class _CardFace extends StatelessWidget {
  final Widget child;
  final bool back;

  const _CardFace({super.key, required this.child, this.back = false});

  @override
  Widget build(BuildContext context) {
    return ReviewCardFrame(back: back, child: child);
  }
}

/// 评分 → 离场方向映射（相对卡片尺寸的分数偏移）。
/// 方向即语义：忘记回落、熟悉生长、模糊悬置。
Offset _exitOffsetFor(String? rating) {
  switch (rating) {
    case 'FORGET':
      return const Offset(-0.12, 0.10);
    case 'FAMILIAR':
      return const Offset(0.12, -0.10);
    case 'VAGUE':
      return const Offset(0, 0.05);
    default:
      return const Offset(0, 0.03);
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
          TtsButton(side: 'front', content: card.front),
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
          if (card.learningMode) const SizedBox(width: 4),
          TtsButton(side: 'back', content: card.back ?? ''),
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
  const _CompleteView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.karisColors;
    final mode = ref.watch(reviewProvider.select((s) => s.mode));
    final sessionTotal = ref.watch(
      reviewProvider.select((s) => s.sessionTotal),
    );
    final reviewedCount = ref.watch(
      reviewProvider.select((s) => s.reviewedCount),
    );
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: KarisEntrance(
          duration: KarisMotion.grow,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 完成徽章：记忆刻度环收满 → 外缘刻度级联点亮 → 印章落戳。
              // 环与首页「今日完成度环」呼应——此处 progress 到顶表示本轮
              // 记忆刻度闭合；收尾以印章封存，让「完成」值得每天看一次。
              _CompletionBadge(mode: mode),
              const SizedBox(height: 16),
              KarisHeading(
                child: Text(
                  mode == 'new' ? '本轮学习完成' : '今日复习完成',
                  style: karisDisplay(fontSize: 28, color: colors.ink),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mode == 'new'
                    ? '本次 $sessionTotal 张 · 已学习 $reviewedCount'
                    : '本次 $sessionTotal 张 · 已复习 $reviewedCount',
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
                      final state = ref.read(reviewProvider);
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

/// 完成徽章：环收满 → 外缘刻度级联点亮 → cinnabar 印章落戳。
///
/// 三段式收尾是「完成」的仪式：弧先合拢、刻度再依次亮起、最后落章封存。
/// 全程 ≤1.5s，克制不浮夸；reduced-motion 直接呈现终态。
class _CompletionBadge extends StatefulWidget {
  final String mode;

  const _CompletionBadge({required this.mode});

  @override
  State<_CompletionBadge> createState() => _CompletionBadgeState();
}

class _CompletionBadgeState extends State<_CompletionBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // 读 MediaQuery 必须在 didChangeDependencies（initState 不可用）：
    // reduced-motion 直接呈现终态，否则完整播放三段式收尾。
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final scale = _segment(t, 0.0, 0.4, Curves.easeOutBack);
        final tickLight = _segment(t, 0.4, 0.75, Curves.easeOut);
        final stamp = _segment(t, 0.78, 1.0, Curves.easeOutBack);
        return Transform.scale(
          scale: 0.7 + 0.3 * scale,
          child: SizedBox(
            width: 78,
            height: 78,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: MemoryRing(
                    progress: 1,
                    strokeWidth: 2.5,
                    tickLength: 3,
                    tickCount: 28,
                    tickProgress: tickLight,
                    duration: KarisMotion.grow,
                  ),
                ),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: colors.jade,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.check, color: colors.surface, size: 26),
                ),
                // 印章落戳：cinnabar 的第二合法语义。装饰性元素排除语义，
                // 完成信息由下方标题朗读，避免屏幕阅读器重复。
                Positioned(
                  right: -12,
                  bottom: -10,
                  child: ExcludeSemantics(
                    child: Opacity(
                      // easeOutBack 会过冲（>1），Opacity 只接受 0..1，
                      // 钳制透明度的同时保留 scale 的弹性回弹。
                      opacity: stamp.clamp(0.0, 1.0),
                      child: Transform.rotate(
                        angle: -0.12,
                        child: Transform.scale(
                          scale: 0.6 + 0.4 * stamp,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: colors.cinnabar,
                                width: 1.4,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.mode == 'new' ? '本轮毕' : '今日毕',
                              style: TextStyle(
                                color: colors.cinnabar,
                                fontFamily: KarisTheme.displayFamily,
                                fontFamilyFallback:
                                    KarisTheme.displayFallbacks,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                height: 1,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 把 [t] 映射到 [start, end] 区间上的 0..1 进度（区间外钳制）。
  double _segment(double t, double start, double end, Curve curve) {
    if (t <= start) return 0;
    if (t >= end) return 1;
    return curve.transform((t - start) / (end - start));
  }
}
