import 'dart:convert';

/// TTS 朗读文本提取与分段。
///
/// 职责：把卡片内容（Quill Delta JSON 或轻量 Markdown）转换为可朗读的
/// 纯文本，再按句子切分、标注语言（zh-CN / en-US），供引擎逐段朗读。
///
/// 全部为纯函数，不依赖平台通道，可直接单测。
///
/// 提取规则：
/// - Delta JSON：只取文本型 insert，embed（LaTeX / 代码块）整体跳过；
/// - Markdown：剥离代码围栏、行间/行内公式（$..$ / $$..$$）、行内代码标记、
///   标题井号、列表符号、粗体/斜体标记；
/// - 语言判定：段内 CJK 字符达到 2 个即判中文（中文引擎对常见英文单词
///   尚可拼读，反之英文引擎读中文体验更差），否则英文。

/// 朗读片段：文本 + 目标语言（对应系统 TTS 的 locale）。
class TtsSegment {
  final String text;
  final String language;

  const TtsSegment(this.text, this.language);

  @override
  bool operator ==(Object other) =>
      other is TtsSegment && other.text == text && other.language == language;

  @override
  int get hashCode => Object.hash(text, language);

  @override
  String toString() => 'TtsSegment($language: $text)';
}

final RegExp _cjkRegex = RegExp(r'[\u4e00-\u9fff\u3400-\u4dbf]');
final RegExp _latinRegex = RegExp(r'[a-zA-Z]');

/// 提取整张卡片的可朗读纯文本（Delta / Markdown / 纯文本统一入口）。
String extractSpeakableText(String content) {
  final trimmed = content.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.startsWith('[')) {
    final deltaText = _extractDeltaText(trimmed);
    if (deltaText != null) return deltaText;
  }
  return _extractMarkdownText(content);
}

/// 从 Quill Delta JSON 提取纯文本；无法解析返回 null（由调用方回退 Markdown）。
String? _extractDeltaText(String content) {
  try {
    final json = jsonDecode(content);
    if (json is! List) return null;
    final buffer = StringBuffer();
    for (final op in json) {
      if (op is! Map<String, dynamic>) continue;
      final insert = op['insert'];
      // String → 文本；Map → embed（latex/code），朗读时跳过。
      if (insert is String) {
        buffer.write(insert);
      }
    }
    return buffer.toString().trim();
  } catch (_) {
    return null;
  }
}

/// Markdown → 纯文本。剥离顺序有讲究：
/// 代码围栏先于一切（代码永不进入行内解析），行内代码取原文，
/// 粗体先于斜体（避免 `**bold**` 被斜体正则吃成 `*bold`）。
String _extractMarkdownText(String content) {
  var text = content;
  // 代码围栏整体替换为换行（独立成句），公式替换为空格（行内居多）。
  text = text.replaceAll(RegExp(r'```[\w+-]*\n?[\s\S]*?```'), '\n');
  text = text.replaceAll(RegExp(r'\$\$(.+?)\$\$', dotAll: true), ' ');
  text = text.replaceAll(RegExp(r'\$([^$\n]+?)\$'), ' ');
  text = text.replaceAllMapped(
    RegExp(r'`([^`]+)`'),
    (m) => m.group(1)!,
  );
  text = text.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');
  text = text.replaceAll(RegExp(r'^[-*]\s+', multiLine: true), '');
  text = text.replaceAllMapped(
    RegExp(r'\*\*([^*]+)\*\*'),
    (m) => m.group(1)!,
  );
  text = text.replaceAllMapped(
    RegExp(r'\*([^*]+)\*'),
    (m) => m.group(1)!,
  );
  text = text.replaceAll(RegExp(r'[ \t]+'), ' ');
  text = text.replaceAll(RegExp(r'\n[ \t]*\n'), '\n');
  text = text.replaceAll(RegExp(r'\n{2,}'), '\n');
  return text.trim();
}

/// 按句子切分并标注语言，相邻同语言片段合并。
///
/// 切分符：句号/问号/感叹号/分号/换行（中英文标点）。标点保留在片段末尾，
/// 引擎按片段连读时自然形成停顿。
List<TtsSegment> splitForSpeech(String text) {
  final raw = text.trim();
  if (raw.isEmpty) return const [];

  final segments = <TtsSegment>[];
  for (final sentence in _splitSentences(raw)) {
    final trimmed = sentence.trim();
    if (trimmed.isEmpty) continue;
    final lang = detectLanguage(trimmed);
    if (segments.isNotEmpty && segments.last.language == lang) {
      segments[segments.length - 1] = TtsSegment(
        '${segments.last.text} $trimmed',
        lang,
      );
    } else {
      segments.add(TtsSegment(trimmed, lang));
    }
  }
  return segments;
}

List<String> _splitSentences(String text) {
  // 在句末标点后插入分隔符再按分隔符切分，保留标点本身。
  final marked = text.replaceAllMapped(
    RegExp(r'[。！？；.!?;]\s*|\n'),
    (m) => '${m.group(0)!.trimRight()}\u0001',
  );
  return marked
      .split('\u0001')
      .where((s) => s.trim().isNotEmpty)
      .map((s) => s.trim())
      .toList();
}

/// 判定片段语言：CJK ≥ 2 字符判中文，纯拉丁/无字母判英文。
String detectLanguage(String text) {
  var cjk = 0;
  var latin = 0;
  for (final rune in text.runes) {
    final ch = String.fromCharCode(rune);
    if (_cjkRegex.hasMatch(ch)) {
      cjk++;
    } else if (_latinRegex.hasMatch(ch)) {
      latin++;
    }
  }
  if (cjk >= 2) return 'zh-CN';
  return latin >= 3 || cjk == 0 ? 'en-US' : 'zh-CN';
}
