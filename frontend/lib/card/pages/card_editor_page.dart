import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/widgets/adaptive_scaffold.dart';
import '../../shared/widgets/rich_card_content.dart';
import '../../shared/widgets/section_widgets.dart';
import '../providers/card_provider.dart';

class CardEditorArgs {
  final String deckId;
  final String? cardId;
  final String? initialFront;
  final String? initialBack;
  final String? title;
  final bool localOnly;

  const CardEditorArgs({
    required this.deckId,
    this.cardId,
    this.initialFront,
    this.initialBack,
    this.title,
    this.localOnly = false,
  });
}

class CardEditorPage extends ConsumerStatefulWidget {
  final CardEditorArgs args;

  const CardEditorPage({super.key, required this.args});

  @override
  ConsumerState<CardEditorPage> createState() => _CardEditorPageState();
}

enum _CardSide { front, back }

class _CardEditorPageState extends ConsumerState<CardEditorPage> {
  late quill.QuillController _frontController;
  late quill.QuillController _backController;
  late FocusNode _frontFocusNode;
  late FocusNode _backFocusNode;
  late ScrollController _frontScrollController;
  late ScrollController _backScrollController;
  _CardSide _side = _CardSide.front;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _frontController = _buildController(widget.args.initialFront ?? '');
    _backController = _buildController(widget.args.initialBack ?? '');
    _frontFocusNode = FocusNode();
    _backFocusNode = FocusNode();
    _frontScrollController = ScrollController();
    _backScrollController = ScrollController();
  }

  quill.QuillController _buildController(String content) {
    final controller = quill.QuillController(
      document: quill.Document(),
      selection: const TextSelection.collapsed(offset: 0),
    );
    final trimmed = content.trim();
    if (trimmed.startsWith('[')) {
      try {
        final doc = quill.Document.fromJson(
          jsonDecode(trimmed) as List<dynamic>,
        );
        return quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {}
    }
    if (content.isNotEmpty) {
      controller.document.insert(0, content);
    }
    return controller;
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _frontFocusNode.dispose();
    _backFocusNode.dispose();
    _frontScrollController.dispose();
    _backScrollController.dispose();
    super.dispose();
  }

  String _serialize(quill.QuillController controller) {
    return jsonEncode(controller.document.toDelta().toJson());
  }

  Future<void> _save() async {
    final front = _serialize(_frontController);
    final back = _serialize(_backController);
    if (_frontController.document.toPlainText().trim().isEmpty ||
        _backController.document.toPlainText().trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('正面和反面内容不能为空')));
      return;
    }

    if (widget.args.localOnly) {
      if (mounted) Navigator.pop(context, (front, back));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(
        cardListProvider(CardListArgs(widget.args.deckId, 'all')).notifier,
      );
      if (widget.args.cardId == null) {
        await notifier.createCard(front, back);
      } else {
        await notifier.updateCard(widget.args.cardId!, front, back);
      }
      if (mounted) Navigator.pop(context, (front, back));
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
  }

  Future<void> _insertLatex(quill.QuillController controller) async {
    final latex = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final textController = TextEditingController();
        return AlertDialog(
          title: const Text('插入 LaTeX 公式'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '公式',
              hintText: '例如 x^2 + y^2 = z^2',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, textController.text),
              child: const Text('插入'),
            ),
          ],
        );
      },
    );
    if (latex == null || latex.trim().isEmpty) return;
    final index = controller.selection.baseOffset;
    controller.document.insert(index, LatexEmbed(latex.trim()));
    _advanceAfterEmbed(controller, index);
  }

  Future<void> _insertCode(quill.QuillController controller) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (ctx) {
        final languageController = TextEditingController(text: 'dart');
        final codeController = TextEditingController();
        return AlertDialog(
          title: const Text('插入代码块'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: languageController,
                decoration: const InputDecoration(
                  labelText: '语言',
                  hintText: 'dart, java, python...',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: '代码',
                  hintText: '粘贴代码...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, (
                languageController.text.trim(),
                codeController.text,
              )),
              child: const Text('插入'),
            ),
          ],
        );
      },
    );
    if (result == null || result.$2.trim().isEmpty) return;
    final index = controller.selection.baseOffset;
    controller.document.insert(
      index,
      CodeEmbed(result.$1.isEmpty ? 'text' : result.$1, result.$2),
    );
    _advanceAfterEmbed(controller, index);
  }

  void _advanceAfterEmbed(quill.QuillController controller, int index) {
    final newIndex = index + 1;
    if (controller.document.length <= newIndex) {
      controller.document.insert(newIndex, '\n');
    }
    controller.updateSelection(
      TextSelection.collapsed(offset: newIndex),
      quill.ChangeSource.local,
    );
  }

  void _goBack() {
    if (context.canPop()) {
      Navigator.pop(context);
    } else {
      context.go('/decks/${widget.args.deckId}/cards');
    }
  }

  @override
  Widget build(BuildContext context) {
    final embedBuilders = const [LatexEmbedBuilder(), CodeEmbedBuilder()];

    return Scaffold(
      backgroundColor: KarisColors.paper,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                _buildHeader(),
                _buildSideSwitch(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _side == _CardSide.front
                        ? _buildEditor(
                            controller: _frontController,
                            focusNode: _frontFocusNode,
                            scrollController: _frontScrollController,
                            embedBuilders: embedBuilders,
                            onLatex: () => _insertLatex(_frontController),
                            onCode: () => _insertCode(_frontController),
                          )
                        : _buildEditor(
                            controller: _backController,
                            focusNode: _backFocusNode,
                            scrollController: _backScrollController,
                            embedBuilders: embedBuilders,
                            onLatex: () => _insertLatex(_backController),
                            onCode: () => _insertCode(_backController),
                          ),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Row(
        children: [
          KarisIconButton(
            icon: Icons.arrow_back,
            tooltip: '返回',
            onPressed: _isSaving ? null : _goBack,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Kicker('卡片'),
                const SizedBox(height: 4),
                Text(
                  widget.args.title ??
                      (widget.args.cardId == null ? '新建卡片' : '编辑卡片'),
                  style: karisDisplay(fontSize: 22),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideSwitch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<_CardSide>(
          segments: const [
            ButtonSegment(value: _CardSide.front, label: Text('正面')),
            ButtonSegment(value: _CardSide.back, label: Text('反面')),
          ],
          selected: {_side},
          onSelectionChanged: (selection) {
            setState(() => _side = selection.first);
          },
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.standard),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: KarisColors.paper,
        border: Border(top: BorderSide(color: KarisColors.hairline)),
      ),
      child: KarisPrimaryButton(
        label: _isSaving ? '保存中...' : '保存',
        icon: Icons.save_outlined,
        onPressed: _isSaving ? null : _save,
      ),
    );
  }

  Widget _buildEditor({
    required quill.QuillController controller,
    required FocusNode focusNode,
    required ScrollController scrollController,
    required List<quill.EmbedBuilder> embedBuilders,
    required VoidCallback onLatex,
    required VoidCallback onCode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: KarisColors.surface,
        border: Border.all(color: KarisColors.hairline),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildToolbar(
            controller: controller,
            onLatex: onLatex,
            onCode: onCode,
          ),
          const Divider(height: 1),
          Expanded(
            child: RepaintBoundary(
              child: quill.QuillEditor.basic(
                controller: controller,
                focusNode: focusNode,
                scrollController: scrollController,
                config: quill.QuillEditorConfig(
                  scrollable: true,
                  expands: true,
                  placeholder: '输入内容...',
                  padding: const EdgeInsets.all(12),
                  embedBuilders: embedBuilders,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar({
    required quill.QuillController controller,
    required VoidCallback onLatex,
    required VoidCallback onCode,
  }) {
    return RepaintBoundary(
      child: Container(
        height: 52,
        color: KarisColors.surface,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              _toolbarIconButton(
                icon: Icons.undo,
                tooltip: '撤销',
                onPressed: controller.undo,
              ),
              _toolbarIconButton(
                icon: Icons.redo,
                tooltip: '重做',
                onPressed: controller.redo,
              ),
              _toolbarIconButton(
                icon: Icons.format_bold,
                tooltip: '加粗',
                onPressed: () =>
                    _toggleAttribute(controller, quill.Attribute.bold),
              ),
              _toolbarIconButton(
                icon: Icons.format_italic,
                tooltip: '斜体',
                onPressed: () =>
                    _toggleAttribute(controller, quill.Attribute.italic),
              ),
              _toolbarIconButton(
                icon: Icons.format_underline,
                tooltip: '下划线',
                onPressed: () =>
                    _toggleAttribute(controller, quill.Attribute.underline),
              ),
              _toolbarIconButton(
                icon: Icons.format_strikethrough,
                tooltip: '删除线',
                onPressed: () =>
                    _toggleAttribute(controller, quill.Attribute.strikeThrough),
              ),
              _toolbarIconButton(
                icon: Icons.code,
                tooltip: '行内代码',
                onPressed: () =>
                    _toggleAttribute(controller, quill.Attribute.inlineCode),
              ),
              _toolbarIconButton(
                icon: Icons.title,
                tooltip: '标题',
                onPressed: () => _pickHeader(controller),
              ),
              _toolbarIconButton(
                icon: Icons.format_list_numbered,
                tooltip: '有序列表',
                onPressed: () => _toggleAttribute(
                  controller,
                  quill.Attribute.ol,
                  expectedValue: 'ordered',
                ),
              ),
              _toolbarIconButton(
                icon: Icons.format_list_bulleted,
                tooltip: '无序列表',
                onPressed: () => _toggleAttribute(
                  controller,
                  quill.Attribute.ul,
                  expectedValue: 'bullet',
                ),
              ),
              _toolbarIconButton(
                icon: Icons.terminal,
                tooltip: '代码块',
                onPressed: () =>
                    _toggleAttribute(controller, quill.Attribute.codeBlock),
              ),
              _toolbarIconButton(
                icon: Icons.format_clear,
                tooltip: '清除格式',
                onPressed: () => _clearFormat(controller),
              ),
              _toolbarIconButton(
                icon: Icons.color_lens,
                tooltip: '文字颜色',
                onPressed: () => _pickColor(controller, background: false),
              ),
              _toolbarIconButton(
                icon: Icons.format_color_fill,
                tooltip: '背景颜色',
                onPressed: () => _pickColor(controller, background: true),
              ),
              _toolbarIconButton(
                icon: Icons.functions,
                tooltip: '插入公式',
                onPressed: onLatex,
              ),
              _toolbarIconButton(
                icon: Icons.code,
                tooltip: '插入代码',
                onPressed: onCode,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolbarIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        minimumSize: const Size(40, 40),
        padding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _toggleAttribute(
    quill.QuillController controller,
    quill.Attribute attribute, {
    Object? expectedValue,
  }) {
    final current = controller.getSelectionStyle().attributes[attribute.key];
    final active =
        current != null &&
        (expectedValue == null || current.value == expectedValue);
    controller.formatSelection(
      active ? quill.Attribute.clone(attribute, null) : attribute,
    );
  }

  void _clearFormat(quill.QuillController controller) {
    final attributes = <quill.Attribute>{};
    for (final style in controller.getAllSelectionStyles()) {
      attributes.addAll(style.values);
    }
    for (final attribute in attributes) {
      controller.formatSelection(quill.Attribute.clone(attribute, null));
    }
  }

  Future<void> _pickHeader(quill.QuillController controller) async {
    final choice = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('标题'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 0),
            child: const Text('正文'),
          ),
          for (var level = 1; level <= 4; level++)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, level),
              child: Text('H$level'),
            ),
        ],
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 0) {
      controller.formatSelection(quill.Attribute.header);
    } else if (choice == 1) {
      controller.formatSelection(quill.Attribute.h1);
    } else if (choice == 2) {
      controller.formatSelection(quill.Attribute.h2);
    } else if (choice == 3) {
      controller.formatSelection(quill.Attribute.h3);
    } else {
      controller.formatSelection(quill.Attribute.h4);
    }
  }

  Future<void> _pickColor(
    quill.QuillController controller, {
    required bool background,
  }) async {
    final result = await showDialog<_EditorColorResult>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(background ? '背景颜色' : '文字颜色'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final color in _editorColorPresets)
              InkWell(
                onTap: () => Navigator.pop(ctx, _EditorColorResult(color)),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: KarisColors.hairline),
                  ),
                ),
              ),
            Tooltip(
              message: '清除颜色',
              child: InkWell(
                onTap: () =>
                    Navigator.pop(ctx, const _EditorColorResult.clear()),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: KarisColors.paper,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: KarisColors.hairline),
                  ),
                  child: const Icon(
                    Icons.format_color_reset,
                    size: 18,
                    color: KarisColors.stone,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
        ],
      ),
    );
    if (!mounted || result == null) return;
    final attribute = background
        ? quill.Attribute.background
        : quill.Attribute.color;
    controller.formatSelection(
      result.clear
          ? quill.Attribute.clone(attribute, null)
          : quill.Attribute.clone(attribute, _colorHex(result.color!)),
    );
  }

  String _colorHex(Color color) {
    final value = color.toARGB32() & 0xFFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0')}';
  }
}

class _EditorColorResult {
  const _EditorColorResult(this.color) : clear = false;

  const _EditorColorResult.clear() : color = null, clear = true;

  final Color? color;
  final bool clear;
}

const List<Color> _editorColorPresets = [
  Color(0xFF202B27),
  Color(0xFFC45B43),
  Color(0xFF2F6B5C),
  Color(0xFFB98A2F),
  Color(0xFF3B6EA5),
  Color(0xFF8A4F9D),
  Color(0xFF66716B),
];
