import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';


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
      final decoded = jsonDecode(trimmed);
      if (decoded is! List) return false;
      _document = quill.Document.fromJson(decoded);
      _quillController = quill.QuillController(
        document: _document!,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
      _focusNode = FocusNode();
      _scrollController = ScrollController();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void didUpdateWidget(covariant RichCardContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
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
    if (_isDelta && _quillController != null && _focusNode != null && _scrollController != null) {
      return quill.QuillEditor.basic(
        controller: _quillController!,
        focusNode: _focusNode,
        scrollController: _scrollController,
        config: quill.QuillEditorConfig(
          autoFocus: false,
          expands: false,
          padding: EdgeInsets.zero,
          embedBuilders: [LatexEmbedBuilder(), CodeEmbedBuilder()],
        ),
      );
    }
    return _MarkdownContent(
      content: widget.content,
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
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
        if (decoded.containsKey(latexType)) return LatexEmbed(decoded[latexType] as String);
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
  CodeEmbed(String language, String code) : super('code', jsonEncode({'language': language, 'code': code}));

  static String get codeType => 'code';

  static String encode(String language, String code) =>
      jsonEncode({codeType: {'language': language, 'code': code}});

  static (String, String)? tryDecode(String data) {
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('language')) {
          return (decoded['language'] as String? ?? '', decoded['code'] as String? ?? '');
        }
        final raw = decoded[codeType];
        if (raw is Map<String, dynamic>) {
          return (raw['language'] as String? ?? '', raw['code'] as String? ?? '');
        }
        if (raw is String) {
          try {
            final inner = jsonDecode(raw);
            if (inner is Map<String, dynamic>) {
              return (inner['language'] as String? ?? '', inner['code'] as String? ?? '');
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
              child: Text(language,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: HighlightView(
              code,
              language: _resolveLanguage(language) ?? 'plaintext',
              theme: githubTheme,
              padding: const EdgeInsets.all(12),
              textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String? _resolveLanguage(String language) {
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
    final segments = _splitCodeFences(content);
    final children = <Widget>[];

    for (final segment in segments) {
      if (segment.isCode) {
        children.add(Container(
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  color: Colors.black.withValues(alpha: 0.04),
                  child: Text(segment.language,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: HighlightView(
                  segment.text,
                  language: _languageName(segment.language) ?? 'plaintext',
                  theme: githubTheme,
                  padding: const EdgeInsets.all(12),
                  textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ),
            ],
          ),
        ));
      } else {
        final lines = segment.text.split('\n');
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.startsWith('#')) {
            var level = 0;
            while (level < trimmed.length && trimmed[level] == '#') {
              level++;
            }
            children.add(Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                trimmed.substring(level).trim(),
                style: effectiveStyle.copyWith(
                  fontSize: (effectiveStyle.fontSize ?? 16) + (4 - level.clamp(1, 4)) * 2,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: maxLines,
                overflow: maxLines != null ? TextOverflow.ellipsis : null,
              ),
            ));
          } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
            children.add(Padding(
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
            ));
          } else {
            children.add(Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: _InlineRichText(
                text: line,
                style: effectiveStyle,
                textAlign: textAlign,
                maxLines: maxLines,
              ),
            ));
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

  String? _languageName(String language) {
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
      result.add(_CodeSegment(isCode: false, text: content.substring(lastEnd, match.start)));
    }
    result.add(_CodeSegment(
      isCode: true,
      text: match.group(2) ?? '',
      language: match.group(1) ?? '',
    ));
    lastEnd = match.end;
  }
  if (lastEnd < content.length) {
    result.add(_CodeSegment(isCode: false, text: content.substring(lastEnd)));
  }
  return result;
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
    final spans = <InlineSpan>[];
    _parseInline(text, style, spans);
    return Text.rich(
      TextSpan(children: spans),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );
  }

  void _parseInline(String text, TextStyle baseStyle, List<InlineSpan> out) {
    // Display math: $$...$$
    final displayMath = RegExp(r'\$\$(.+?)\$\$', dotAll: true);
    var index = 0;
    for (final match in displayMath.allMatches(text)) {
      if (match.start > index) {
        _parseInlineMathAndFormat(text.substring(index, match.start), baseStyle, out, isMathDisplay: false);
      }
      out.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Math.tex(
          match.group(1)!,
          mathStyle: MathStyle.display,
          textStyle: baseStyle.copyWith(fontSize: (baseStyle.fontSize ?? 16) + 2),
        ),
      ));
      index = match.end;
    }
    if (index < text.length) {
      _parseInlineMathAndFormat(text.substring(index), baseStyle, out, isMathDisplay: false);
    }
  }

  void _parseInlineMathAndFormat(String text, TextStyle baseStyle, List<InlineSpan> out, {required bool isMathDisplay}) {
    // Inline math: $...$
    final inlineMath = RegExp(r'\$([^$\n]+?)\$');
    var index = 0;
    for (final match in inlineMath.allMatches(text)) {
      if (match.start > index) {
        _parseFormatting(text.substring(index, match.start), baseStyle, out);
      }
      out.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Math.tex(
          match.group(1)!,
          mathStyle: MathStyle.text,
          textStyle: baseStyle.copyWith(fontSize: (baseStyle.fontSize ?? 16) - 1),
        ),
      ));
      index = match.end;
    }
    if (index < text.length) {
      _parseFormatting(text.substring(index), baseStyle, out);
    }
  }

  void _parseFormatting(String text, TextStyle baseStyle, List<InlineSpan> out) {
    // Bold
    final bold = RegExp(r'\*\*(.+?)\*\*');
    var index = 0;
    for (final match in bold.allMatches(text)) {
      if (match.start > index) {
        _parseItalicAndCode(text.substring(index, match.start), baseStyle, out);
      }
      out.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(fontWeight: FontWeight.bold),
      ));
      index = match.end;
    }
    if (index < text.length) {
      _parseItalicAndCode(text.substring(index), baseStyle, out);
    }
  }

  void _parseItalicAndCode(String text, TextStyle baseStyle, List<InlineSpan> out) {
    // Inline code
    final inlineCode = RegExp(r'`([^`]+)`');
    var index = 0;
    for (final match in inlineCode.allMatches(text)) {
      if (match.start > index) {
        _parseItalic(text.substring(index, match.start), baseStyle, out);
      }
      out.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(
          fontFamily: 'monospace',
          backgroundColor: const Color(0xFFF0F0F0),
        ),
      ));
      index = match.end;
    }
    if (index < text.length) {
      _parseItalic(text.substring(index), baseStyle, out);
    }
  }

  void _parseItalic(String text, TextStyle baseStyle, List<InlineSpan> out) {
    final italic = RegExp(r'\*([^*]+)\*');
    var index = 0;
    for (final match in italic.allMatches(text)) {
      if (match.start > index) {
        out.add(TextSpan(text: text.substring(index, match.start)));
      }
      out.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(fontStyle: FontStyle.italic),
      ));
      index = match.end;
    }
    if (index < text.length) {
      out.add(TextSpan(text: text.substring(index)));
    }
  }
}