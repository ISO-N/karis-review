import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:highlight/highlight.dart' as hl;
import 'package:flutter_highlight/themes/github.dart';

/// 轻量 LRU 缓存：内容解析结果跨 build/跨列表项复用，
/// 滚动返回或重复内容时零重复解析，缓解大列表拖拽卡顿。
class _LruCache<K, V> {
  _LruCache(this.limit);

  final int limit;
  final LinkedHashMap<K, V> _map = LinkedHashMap<K, V>();

  V? operator [](K key) {
    final value = _map[key];
    if (value != null) {
      // LRU 提升
      _map.remove(key);
      _map[key] = value;
    }
    return value;
  }

  void put(K key, V value) {
    _map.remove(key);
    _map[key] = value;
    if (_map.length > limit) {
      _map.remove(_map.keys.first);
    }
  }
}

/// 代码围栏分割结果缓存（完整渲染场景复用）。
final _LruCache<String, List<_CodeSegment>> _codeFenceCache =
    _LruCache(256);

/// Quill Delta Document 解析结果缓存（同一 Delta 内容不重复 jsonDecode）。
final _LruCache<String, quill.Document> _deltaDocumentCache = _LruCache(128);

/// 行内 Markdown token 解析结果缓存（与 style 无关的中间表示）。
final _LruCache<String, List<_InlineToken>> _inlineTokenCache = _LruCache(512);

/// 代码高亮 parse 结果缓存（code+language → Node 树，词法解析只做一次）。
final _LruCache<String, List<hl.Node>> _highlightParseCache = _LruCache(128);

List<_CodeSegment> _cachedSplitCodeFences(String content) {
  final cached = _codeFenceCache[content];
  if (cached != null) return cached;
  final result = _splitCodeFences(content);
  _codeFenceCache.put(content, result);
  return result;
}

/// 语言映射（供高亮与代码块标签复用）。
String? _resolveHighlightLanguage(String language) {
  return switch (language.toLowerCase()) {
    'dart' => 'dart',
    'java' => 'java',
    'javascript' || 'js' => 'javascript',
    'python' || 'py' => 'python',
    'sql' => 'sql',
    'html' || 'xml' => 'xml',
    _ => null,
  };
}

/// 复刻 flutter_highlight `HighlightView._convert` 的节点 → span 转换。
List<TextSpan> _convertHighlightNodes(
  List<hl.Node> nodes,
  Map<String, TextStyle> theme,
) {
  final spans = <TextSpan>[];
  var currentSpans = spans;
  final stack = <List<TextSpan>>[];

  void traverse(hl.Node node) {
    if (node.value != null) {
      currentSpans.add(
        node.className == null
            ? TextSpan(text: node.value)
            : TextSpan(text: node.value, style: theme[node.className!]),
      );
    } else if (node.children != null) {
      final tmp = <TextSpan>[];
      currentSpans.add(TextSpan(children: tmp, style: theme[node.className!]));
      stack.add(currentSpans);
      currentSpans = tmp;
      final children = node.children!;
      for (final child in children) {
        traverse(child);
        if (identical(child, children.last)) {
          currentSpans = stack.isEmpty ? spans : stack.removeLast();
        }
      }
    }
  }

  for (final node in nodes) {
    traverse(node);
  }
  return spans;
}

/// 带缓存的高亮代码块：同一 code+language 只做一次词法解析（[hl.highlight.parse]），
/// 滚动返回 / 重复代码时直接复用 Node 树再映射 TextSpan，
/// 相比 HighlightView 每次 build 重新解析，滚动成本大幅下降。
class _CachedHighlight extends StatelessWidget {
  final String code;
  final String language;
  final TextStyle textStyle;

  const _CachedHighlight({
    required this.code,
    required this.language,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    const rootKey = 'root';
    const defaultFontColor = Color(0xff000000);
    const defaultBackgroundColor = Color(0xffffffff);
    // 与 HighlightView 一致：tab 展开后再解析。
    final source = code.replaceAll('\t', ' ' * 8);
    final nodes = _cachedHighlightNodes(source, language);
    final rootStyle = TextStyle(
      fontFamily: 'monospace',
      color: githubTheme[rootKey]?.color ?? defaultFontColor,
    ).merge(textStyle);
    return Container(
      color: githubTheme[rootKey]?.backgroundColor ?? defaultBackgroundColor,
      child: RichText(
        text: TextSpan(
          style: rootStyle,
          children: _convertHighlightNodes(nodes, githubTheme),
        ),
      ),
    );
  }

  List<hl.Node> _cachedHighlightNodes(String source, String language) {
    final resolved = _resolveHighlightLanguage(language) ?? 'plaintext';
    final key = '$resolved\u0000$source';
    final cached = _highlightParseCache[key];
    if (cached != null) return cached;
    final nodes = hl.highlight.parse(source, language: resolved).nodes ??
        const <hl.Node>[];
    _highlightParseCache.put(key, nodes);
    return nodes;
  }
}

/// Renders card content as rich text.
///
/// Supports both Quill Delta JSON (created by the card editor) and plain text
/// with lightweight Markdown syntax (bold, italic, headings, lists, inline code,
/// fenced code blocks and LaTeX math).
class RichCardContent extends StatefulWidget {
  final String content;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;

  const RichCardContent({
    super.key,
    required this.content,
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLines,
  });

  @override
  State<RichCardContent> createState() => _RichCardContentState();
}

class _RichCardContentState extends State<RichCardContent> {
  quill.QuillController? _quillController;
  quill.Document? _document;
  FocusNode? _focusNode;
  ScrollController? _scrollController;
  bool _isDelta = false;

  @override
  void initState() {
    super.initState();
    _isDelta = _tryParseDelta(widget.content);
  }

  bool _tryParseDelta(String content) {
    final trimmed = content.trim();
    if (!trimmed.startsWith('[')) return false;
    try {
      final cached = _deltaDocumentCache[trimmed];
      _document = cached ?? quill.Document.fromJson(jsonDecode(trimmed));
      if (cached == null) {
        _deltaDocumentCache.put(trimmed, _document!);
      }
      if (widget.maxLines == null) {
        _quillController = quill.QuillController(
          document: _document!,
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: true,
        );
        _focusNode = FocusNode();
        _scrollController = ScrollController();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void didUpdateWidget(covariant RichCardContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content ||
        oldWidget.maxLines != widget.maxLines) {
      _disposeQuill();
      _isDelta = _tryParseDelta(widget.content);
    }
  }

  void _disposeQuill() {
    _quillController?.dispose();
    _focusNode?.dispose();
    _scrollController?.dispose();
    _quillController = null;
    _focusNode = null;
    _scrollController = null;
    _document = null;
  }

  @override
  void dispose() {
    _disposeQuill();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDelta && _document != null) {
      if (widget.maxLines != null) {
        return _DeltaPreview(
          document: _document!,
          style: widget.style,
          textAlign: widget.textAlign,
          maxLines: widget.maxLines,
        );
      }
      if (_quillController != null &&
          _focusNode != null &&
          _scrollController != null) {
        return quill.QuillEditor.basic(
          controller: _quillController!,
          focusNode: _focusNode,
          scrollController: _scrollController,
          config: quill.QuillEditorConfig(
            autoFocus: false,
            scrollable: false,
            expands: false,
            padding: EdgeInsets.zero,
            embedBuilders: [LatexEmbedBuilder(), CodeEmbedBuilder()],
          ),
        );
      }
    }
    return _MarkdownContent(
      content: widget.content,
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
    );
  }
}

class _DeltaPreview extends StatelessWidget {
  final quill.Document document;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;

  const _DeltaPreview({
    required this.document,
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final text = document.toPlainText([
      LatexEmbedBuilder(),
      CodeEmbedBuilder(),
    ]);
    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
    return Text(
      text,
      style: effectiveStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      // 与行内预览一致：clip 避免全文测量（ellipsis 需完整排版来确定截断）。
      overflow: maxLines != null ? TextOverflow.clip : null,
    );
  }
}

class LatexEmbed extends quill.CustomBlockEmbed {
  const LatexEmbed(String latex) : super('latex', latex);

  static String get latexType => 'latex';

  static String encode(String latex) => jsonEncode({latexType: latex});

  static LatexEmbed? tryDecode(String data) {
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey(latexType)) {
          return LatexEmbed(decoded[latexType] as String);
        }
      } else if (decoded is String) {
        return LatexEmbed(decoded);
      }
    } catch (_) {}
    return null;
  }
}

class LatexEmbedBuilder extends quill.EmbedBuilder {
  const LatexEmbedBuilder();

  @override
  String get key => LatexEmbed.latexType;

  @override
  String toPlainText(quill.Embed node) {
    final data = node.value.data;
    if (data is String) {
      final latex = LatexEmbed.tryDecode(data);
      if (latex != null) return latex.data as String;
      return data;
    }
    return '';
  }

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    final data = embedContext.node.value.data;
    String latex = '';
    if (data is String) {
      final decoded = LatexEmbed.tryDecode(data);
      latex = decoded?.data as String? ?? data;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Math.tex(
            latex,
            mathStyle: MathStyle.display,
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}

class CodeEmbed extends quill.CustomBlockEmbed {
  CodeEmbed(String language, String code)
    : super('code', jsonEncode({'language': language, 'code': code}));

  static String get codeType => 'code';

  static String encode(String language, String code) => jsonEncode({
    codeType: {'language': language, 'code': code},
  });

  static (String, String)? tryDecode(String data) {
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('language')) {
          return (
            decoded['language'] as String? ?? '',
            decoded['code'] as String? ?? '',
          );
        }
        final raw = decoded[codeType];
        if (raw is Map<String, dynamic>) {
          return (
            raw['language'] as String? ?? '',
            raw['code'] as String? ?? '',
          );
        }
        if (raw is String) {
          try {
            final inner = jsonDecode(raw);
            if (inner is Map<String, dynamic>) {
              return (
                inner['language'] as String? ?? '',
                inner['code'] as String? ?? '',
              );
            }
          } catch (_) {}
          return ('', raw);
        }
      }
    } catch (_) {}
    return null;
  }
}

class CodeEmbedBuilder extends quill.EmbedBuilder {
  const CodeEmbedBuilder();

  @override
  String get key => CodeEmbed.codeType;

  @override
  String toPlainText(quill.Embed node) {
    final data = node.value.data;
    if (data is String) {
      final decoded = CodeEmbed.tryDecode(data);
      if (decoded != null) return decoded.$2;
      return data;
    }
    return '';
  }

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    final data = embedContext.node.value.data;
    String language = '';
    String code = '';
    if (data is String) {
      final decoded = CodeEmbed.tryDecode(data);
      if (decoded != null) {
        language = decoded.$1;
        code = decoded.$2;
      } else {
        code = data;
      }
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (language.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: Colors.black.withValues(alpha: 0.04),
              child: Text(
                language,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _CachedHighlight(
                code: code,
                language: language,
                textStyle: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A lightweight Markdown/LaTeX/code renderer used for cards that are not
/// stored as Quill Delta JSON.
class _MarkdownContent extends StatelessWidget {
  final String content;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;

  const _MarkdownContent({
    required this.content,
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;

    // Split code fences out first so code is never passed through the inline parser.
    final segments = _cachedSplitCodeFences(content);
    final children = <Widget>[];

    for (final segment in segments) {
      if (segment.isCode) {
        children.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (segment.language.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    color: Colors.black.withValues(alpha: 0.04),
                    child: Text(
                      segment.language,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _CachedHighlight(
                      code: segment.text,
                      language: segment.language,
                      textStyle: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        final lines = segment.text.split('\n');
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.startsWith('#')) {
            var level = 0;
            while (level < trimmed.length && trimmed[level] == '#') {
              level++;
            }
            children.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  trimmed.substring(level).trim(),
                  style: effectiveStyle.copyWith(
                    fontSize:
                        (effectiveStyle.fontSize ?? 16) +
                        (4 - level.clamp(1, 4)) * 2,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: maxLines,
                  overflow: maxLines != null ? TextOverflow.ellipsis : null,
                ),
              ),
            );
          } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
            children.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Text('•'),
                    ),
                    Expanded(
                      child: _InlineRichText(
                        text: trimmed.substring(2),
                        style: effectiveStyle,
                        textAlign: textAlign,
                        maxLines: maxLines,
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            children.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: _InlineRichText(
                  text: line,
                  style: effectiveStyle,
                  textAlign: textAlign,
                  maxLines: maxLines,
                ),
              ),
            );
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class _CodeSegment {
  final bool isCode;
  final String text;
  final String language;

  _CodeSegment({required this.isCode, required this.text, this.language = ''});
}

List<_CodeSegment> _splitCodeFences(String content) {
  final result = <_CodeSegment>[];
  final regex = RegExp(r'```([\w+-]*)\n?([\s\S]*?)```');
  var lastEnd = 0;
  for (final match in regex.allMatches(content)) {
    if (match.start > lastEnd) {
      result.add(
        _CodeSegment(
          isCode: false,
          text: content.substring(lastEnd, match.start),
        ),
      );
    }
    result.add(
      _CodeSegment(
        isCode: true,
        text: match.group(2) ?? '',
        language: match.group(1) ?? '',
      ),
    );
    lastEnd = match.end;
  }
  if (lastEnd < content.length) {
    result.add(_CodeSegment(isCode: false, text: content.substring(lastEnd)));
  }
  return result;
}

/// 行内 Markdown 解析 token（与 style 无关的中间表示，可安全缓存复用）。
sealed class _InlineToken {
  const _InlineToken();
}

class _TokenText extends _InlineToken {
  const _TokenText(this.text);
  final String text;
}

class _TokenMath extends _InlineToken {
  const _TokenMath(this.latex, {required this.display});
  final String latex;
  final bool display;
}

class _TokenBold extends _InlineToken {
  const _TokenBold(this.text);
  final String text;
}

class _TokenItalic extends _InlineToken {
  const _TokenItalic(this.text);
  final String text;
}

class _TokenCode extends _InlineToken {
  const _TokenCode(this.text);
  final String text;
}

List<_InlineToken> _cachedInlineTokens(String text) {
  final cached = _inlineTokenCache[text];
  if (cached != null) return cached;
  final tokens = <_InlineToken>[];
  _parseInlineTokens(text, tokens);
  _inlineTokenCache.put(text, tokens);
  return tokens;
}

void _parseInlineTokens(String text, List<_InlineToken> out) {
  // Display math: $$...$$
  final displayMath = RegExp(r'\$\$(.+?)\$\$', dotAll: true);
  var index = 0;
  for (final match in displayMath.allMatches(text)) {
    if (match.start > index) {
      _parseInlineMathTokens(text.substring(index, match.start), out);
    }
    out.add(_TokenMath(match.group(1)!, display: true));
    index = match.end;
  }
  if (index < text.length) {
    _parseInlineMathTokens(text.substring(index), out);
  }
}

void _parseInlineMathTokens(String text, List<_InlineToken> out) {
  // Inline math: $...$
  final inlineMath = RegExp(r'\$([^$\n]+?)\$');
  var index = 0;
  for (final match in inlineMath.allMatches(text)) {
    if (match.start > index) {
      _parseFormattingTokens(text.substring(index, match.start), out);
    }
    out.add(_TokenMath(match.group(1)!, display: false));
    index = match.end;
  }
  if (index < text.length) {
    _parseFormattingTokens(text.substring(index), out);
  }
}

void _parseFormattingTokens(String text, List<_InlineToken> out) {
  // Bold
  final bold = RegExp(r'\*\*(.+?)\*\*');
  var index = 0;
  for (final match in bold.allMatches(text)) {
    if (match.start > index) {
      _parseItalicAndCodeTokens(text.substring(index, match.start), out);
    }
    out.add(_TokenBold(match.group(1)!));
    index = match.end;
  }
  if (index < text.length) {
    _parseItalicAndCodeTokens(text.substring(index), out);
  }
}

void _parseItalicAndCodeTokens(String text, List<_InlineToken> out) {
  // Inline code
  final inlineCode = RegExp(r'`([^`]+)`');
  var index = 0;
  for (final match in inlineCode.allMatches(text)) {
    if (match.start > index) {
      _parseItalicTokens(text.substring(index, match.start), out);
    }
    out.add(_TokenCode(match.group(1)!));
    index = match.end;
  }
  if (index < text.length) {
    _parseItalicTokens(text.substring(index), out);
  }
}

void _parseItalicTokens(String text, List<_InlineToken> out) {
  final italic = RegExp(r'\*([^*]+)\*');
  var index = 0;
  for (final match in italic.allMatches(text)) {
    if (match.start > index) {
      out.add(_TokenText(text.substring(index, match.start)));
    }
    out.add(_TokenItalic(match.group(1)!));
    index = match.end;
  }
  if (index < text.length) {
    out.add(_TokenText(text.substring(index)));
  }
}

/// 将缓存的 token 映射为带 style 的 InlineSpan（轻量，无正则）。
///
/// 公式始终用 [Math.tex] 渲染为真实排版：公式是卡片的核心内容，预览
/// （maxLines 限行）也不降级为源码文本。
///
/// 注意：不要在这里对 `SyntaxTree`/解析产物做跨实例缓存——flutter_math_fork
/// 的 [GreenNode] 上带有 `_oldOptions`/`_oldBuildResult` 可变缓存，共享解析
/// 产物会让多个挂载点命中同一个 BuildResult widget 实例，触发 Element 冲突
/// 与语义收集断言（长公式场景实测整屏崩溃）。解析成本是该库的已知边界。
List<InlineSpan> _tokensToSpans(
  List<_InlineToken> tokens,
  TextStyle baseStyle,
) {
  final out = <InlineSpan>[];
  for (final token in tokens) {
    switch (token) {
      case _TokenText(:final text):
        out.add(TextSpan(text: text));
      case _TokenMath(:final latex, :final display):
        out.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Math.tex(
              latex,
              mathStyle: display ? MathStyle.display : MathStyle.text,
              textStyle: baseStyle.copyWith(
                fontSize: (baseStyle.fontSize ?? 16) + (display ? 2 : -1),
              ),
            ),
          ),
        );
      case _TokenBold(:final text):
        out.add(
          TextSpan(
            text: text,
            style: baseStyle.copyWith(fontWeight: FontWeight.bold),
          ),
        );
      case _TokenItalic(:final text):
        out.add(
          TextSpan(
            text: text,
            style: baseStyle.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      case _TokenCode(:final text):
        out.add(
          TextSpan(
            text: text,
            style: baseStyle.copyWith(
              fontFamily: 'monospace',
              backgroundColor: const Color(0xFFF0F0F0),
            ),
          ),
        );
    }
  }
  return out;
}

class _InlineRichText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final int? maxLines;

  const _InlineRichText({
    required this.text,
    required this.style,
    this.textAlign = TextAlign.start,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    // token 列表是缓存的中间表示；是否含公式直接扫描 token 判定，
    // 不再对全文跑两遍正则（旧实现 _hasMath 每次 build 都做 hasMatch）。
    final tokens = _cachedInlineTokens(text);
    final spans = _tokensToSpans(tokens, style);
    final richText = Text.rich(
      TextSpan(children: spans),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      // 限行预览用 clip 而非 ellipsis：省略号需要测量整个文本以确定截断点，
      // 长文本卡（5k 大列表常见）测量成本高；clip 只排版 maxLines 行即停。
      overflow: maxLines != null ? TextOverflow.clip : null,
    );
    if (!_tokensContainMath(tokens)) return richText;

    // 公式行按固有宽度排版并横向滚动，避免长公式被卡片容器裁切。
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) return richText;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.hardEdge,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: richText,
          ),
        );
      },
    );
  }
}

/// token 列表中是否含数学公式（遍历中间表示，无正则开销）。
bool _tokensContainMath(List<_InlineToken> tokens) {
  for (final token in tokens) {
    if (token is _TokenMath) return true;
  }
  return false;
}
