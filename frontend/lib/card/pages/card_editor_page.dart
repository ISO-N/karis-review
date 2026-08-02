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
                  child: SingleChildScrollView(
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
          quill.QuillSimpleToolbar(
            controller: controller,
            config: quill.QuillSimpleToolbarConfig(
              multiRowsDisplay: false,
              showFontFamily: false,
              showFontSize: false,
              showSearchButton: false,
              showQuote: false,
              showIndent: false,
              showLink: false,
              showSubscript: false,
              showSuperscript: false,
              showSmallButton: false,
              showLineHeightButton: false,
              showAlignmentButtons: false,
              showDirection: false,
              showListCheck: false,
              customButtons: [
                quill.QuillToolbarCustomButtonOptions(
                  icon: const Icon(Icons.functions, size: 18),
                  tooltip: '插入公式',
                  onPressed: onLatex,
                ),
                quill.QuillToolbarCustomButtonOptions(
                  icon: const Icon(Icons.code, size: 18),
                  tooltip: '插入代码',
                  onPressed: onCode,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 130),
            child: quill.QuillEditor.basic(
              controller: controller,
              focusNode: focusNode,
              scrollController: scrollController,
              config: quill.QuillEditorConfig(
                placeholder: '输入内容...',
                padding: const EdgeInsets.all(12),
                embedBuilders: embedBuilders,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
