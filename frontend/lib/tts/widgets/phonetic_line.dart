import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../phonetic_dict.dart';

/// 卡片音标行：内容为纯英文单词/短语时，在内容下方显示美式 IPA 音标。
///
/// 静默降级：非纯英文内容（句子、中英混合、公式）或词库未收录时
/// 不渲染任何东西；词库首次加载期间同样不显示（不闪占位）。
class PhoneticLine extends ConsumerStatefulWidget {
  final String content;

  const PhoneticLine({super.key, required this.content});

  @override
  ConsumerState<PhoneticLine> createState() => _PhoneticLineState();
}

class _PhoneticLineState extends ConsumerState<PhoneticLine> {
  Future<String?>? _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(phoneticDictProvider).phoneticFor(widget.content);
  }

  @override
  void didUpdateWidget(covariant PhoneticLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _future = ref.read(phoneticDictProvider).phoneticFor(widget.content);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    return FutureBuilder<String?>(
      future: _future,
      builder: (context, snapshot) {
        final ipa = snapshot.data;
        if (ipa == null || ipa.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '/$ipa/',
            style: TextStyle(
              fontSize: 15,
              color: colors.stone,
              letterSpacing: 0.4,
              fontFamily: KarisTheme.monoFamily,
            ),
          ),
        );
      },
    );
  }
}
