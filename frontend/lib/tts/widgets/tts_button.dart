import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../tts_provider.dart';

/// 卡片朗读按钮（正反面各一个）。
///
/// - 引擎不可用或设置关闭时不占位渲染；
/// - 朗读中显示停止图标，再次点击停止；点击另一面自动切换朗读对象。
class TtsButton extends ConsumerWidget {
  /// 朗读目标面：'front' / 'back'。
  final String side;

  /// 该面的原始内容（Delta JSON 或 Markdown）。
  final String content;

  const TtsButton({
    super.key,
    required this.side,
    required this.content,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tts = ref.watch(ttsProvider);
    if (!tts.available || !tts.enabled) return const SizedBox.shrink();

    final colors = context.karisColors;
    final active = tts.playing && tts.readingSide == side;
    return IconButton(
      onPressed: () =>
          ref.read(ttsProvider.notifier).toggle(side, content),
      icon: Icon(
        active ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
        size: 18,
        color: active ? colors.cinnabar : colors.stone,
      ),
      tooltip: active ? '停止朗读' : '朗读',
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        minimumSize: const Size(30, 30),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
