import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../deck/models/deck.dart';
import '../../deck/providers/deck_provider.dart';
import '../../shared/widgets/adaptive_scaffold.dart';
import '../../shared/utils/motion.dart';
import '../../shared/widgets/app_semantics.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/section_widgets.dart';

import '../../l10n/app_localizations.dart';
class StartFlowPage extends ConsumerStatefulWidget {
  final String initialMode;
  final String? initialDeckId;

  const StartFlowPage({
    super.key,
    this.initialMode = 'due',
    this.initialDeckId,
  });

  @override
  ConsumerState<StartFlowPage> createState() => _StartFlowPageState();
}

class _StartFlowPageState extends ConsumerState<StartFlowPage> {
  late String _mode;
  late String _scope;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode == 'new' ? 'new' : 'due';
    _scope = widget.initialDeckId ?? 'all';
  }

  @override
  void didUpdateWidget(covariant StartFlowPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextMode = widget.initialMode == 'new' ? 'new' : 'due';
    final nextScope = widget.initialDeckId ?? 'all';
    if (nextMode != _mode || nextScope != _scope) {
      _mode = nextMode;
      _scope = nextScope;
    }
  }

  void _setMode(String value) {
    final decks = ref.read(deckListProvider).value ?? const <Deck>[];
    setState(() {
      _mode = value;
      // 切换学习方式后，若原选中卡组在当前模式下无卡，回退到全部。
      _scope = _effectiveScope(_eligibleDecks(decks));
    });
    GoRouter.maybeOf(context)?.replace('/start?mode=$value&deck_id=$_scope');
  }

  void _setScope(String value) {
    setState(() => _scope = value);
    GoRouter.maybeOf(context)?.replace('/start?mode=$_mode&deck_id=$value');
  }
  @override
  Widget build(BuildContext context) {
    final l10n = KarisReviewLocalizations.of(context)!;
    final decksAsync = ref.watch(deckListProvider);
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    return Scaffold(
      backgroundColor: context.karisColors.paper,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, isTablet ? 32 : 20, 20, 44),
              child: decksAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: LoadingWidget(),
                ),
                error: (error, _) => EmptyState(
                  icon: Icons.error_outline,
                  title: l10n.errorLoadFailed,
                  message: l10n.errorLoadFailed,
                ),
                data: (decks) {
                  final eligible = _eligibleDecks(decks);
                  final totalCount = _totalCount(eligible);
                  final scope = _effectiveScope(eligible);
                  final scopeName = scope == 'all' ? '全部卡组' : _scopeName(eligible);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          KarisIconButton(
                            icon: Icons.arrow_back,
                            tooltip: '返回',
                            onPressed: () => context.go('/home'),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Kicker('开始'),
                                SizedBox(height: 4),
                                KarisHeading(
                                  child: Text(
                                    _mode == 'new' ? l10n.startModeNew : l10n.startModeDue,
                                    style: karisDisplay(fontSize: 26),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '$totalCount 张',
                            style: karisMono(
                              fontSize: 12,
                              color: context.karisColors.stone,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 22),
                      const SectionHeader(title: '学习方式', trailing: '选择队列'),
                      SizedBox(height: 14),
                      _ModeSwitch(mode: _mode, onChanged: _setMode),
                      SizedBox(height: 24),
                      SectionHeader(
                        title: '范围',
                        trailing: scopeName,
                      ),
                      SizedBox(height: 14),
                      if (eligible.isEmpty)
                        EmptyState(
                          icon: Icons.layers_outlined,
                          title: _mode == 'new' ? '当前没有待学习的新卡' : '当前没有待复习的卡片',
                          message: '换个学习方式，或先去卡片列表添加新卡',
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: eligible.length + 1,
                          separatorBuilder: (_, _) =>
                              SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _ScopeOption(
                                name: '全部卡组',
                                meta: _countLabel(totalCount),
                                active: _scope == 'all',
                                onTap: () => _setScope('all'),
                                play: true,
                              );
                            }
                            final deck = eligible[index - 1];
                            return _ScopeOption(
                              name: deck.name,
                              meta: _countLabel(
                                _mode == 'new' ? deck.newCount : deck.dueCount,
                              ),
                              active: scope == deck.id,
                              onTap: () => _setScope(deck.id),
                              play: index < 8,
                            );
                          },
                        ),
                      SizedBox(height: 26),
                      KarisPrimaryButton(
                        label: _mode == 'new' ? l10n.startModeNew : l10n.startModeDue,
                        icon: _mode == 'new'
                            ? Icons.auto_stories_outlined
                            : Icons.play_arrow_rounded,
                        onPressed: eligible.isEmpty || totalCount == 0
                            ? null
                            : () => context.go(
                                '/review?mode=$_mode&deck_id=$scope',
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Deck> _eligibleDecks(List<Deck> decks) {
    return decks.where((deck) {
      final count = _mode == 'new' ? deck.newCount : deck.dueCount;
      return count > 0;
    }).toList();
  }

  /// 当前模式下有卡可学的卡组才可选；选中卡组不在范围内时回退到全部。
  String _effectiveScope(List<Deck> eligible) {
    if (_scope == 'all') return 'all';
    for (final deck in eligible) {
      if (deck.id == _scope) return _scope;
    }
    return 'all';
  }

  String _scopeName(List<Deck> eligible) {
    for (final deck in eligible) {
      if (deck.id == _scope) return deck.name;
    }
    return '全部卡组';
  }

  int _totalCount(List<Deck> decks) {
    return decks.fold<int>(
      0,
      (sum, deck) => sum + (_mode == 'new' ? deck.newCount : deck.dueCount),
    );
  }

  String _countLabel(int count) {
    return _mode == 'new' ? '新卡 $count' : '待复习 $count';
  }
}

class _ModeSwitch extends StatelessWidget {
  final String mode;
  final ValueChanged<String> onChanged;

  const _ModeSwitch({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    final l10n = KarisReviewLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.hairline.withValues(alpha: 0.45),
        border: Border.all(color: colors.hairline),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeOption(
              label: l10n.startFilterDue,
              active: mode == 'due',
              onTap: () => onChanged('due'),
            ),
          ),
          Expanded(
            child: _ModeOption(
              label: '学习新卡',
              active: mode == 'new',
              onTap: () => onChanged('new'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeOption({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return KarisInteractive(
      selected: active,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: reducedDuration(context, KarisMotion.feedback),
          curve: KarisMotion.easeOut,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? colors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: (isDark
                              ? const Color(0xFF000000)
                              : const Color(0xFF161F1B))
                          .withValues(alpha: isDark ? 0.35 : 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? colors.ink : colors.stone,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScopeOption extends StatelessWidget {
  final String name;
  final String meta;
  final bool active;
  final VoidCallback onTap;
  final bool play;

  const _ScopeOption({
    required this.name,
    required this.meta,
    required this.active,
    required this.onTap,
    this.play = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    return KarisEntrance(
      play: play,
      child: KarisInteractive(
        selected: active,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 62),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: active ? colors.jadeSoft : colors.surface,
              border: Border.all(
                color: active ? colors.jade : colors.hairline,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: active ? colors.jade : colors.hairline,
                      width: 1.5,
                    ),
                  ),
                  child: active
                      ? Padding(
                          padding: const EdgeInsets.all(4),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.jade,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.ink,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        meta,
                        style:
                            karisMono(fontSize: 10, color: colors.stone),
                      ),
                    ],
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
