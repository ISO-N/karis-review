import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../shared/widgets/adaptive_scaffold.dart';
import '../../shared/widgets/rich_card_content.dart';
import '../../shared/widgets/section_widgets.dart';
import '../providers/card_provider.dart';

class CardEditorSheet extends ConsumerStatefulWidget {
  final String deckId;
  final String? cardId;
  final String? initialFront;
  final String? initialBack;
  final ValueChanged<bool>? onSaved;

  const CardEditorSheet({
    super.key,
    required this.deckId,
    this.cardId,
    this.initialFront,
    this.initialBack,
    this.onSaved,
  });

  @override
  ConsumerState<CardEditorSheet> createState() => _CardEditorSheetState();
}

class _CardEditorSheetState extends ConsumerState<CardEditorSheet> {
  late quill.QuillController _frontController;
  late quill.QuillController _backController;
  late FocusNode _frontFocusNode;
  late FocusNode _backFocusNode;
  late ScrollController _frontScrollController;
  late ScrollController _backScrollController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _frontController = _buildController(widget.initialFront ?? '');
    _backController = _buildController(widget.initialBack ?? '');
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

    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(
        cardListProvider(CardListArgs(widget.deckId, 'all')).notifier,
      );
      if (widget.cardId == null) {
        await notifier.createCard(front, back);
      } else {
        await notifier.updateCard(widget.cardId!, front, back);
      }
      widget.onSaved?.call(true);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    final embedBuilders = const [LatexEmbedBuilder(), CodeEmbedBuilder()];

    return SafeArea(
      top: false,
      child: Center(
        child: Container(
          width: isTablet ? 720 : double.infinity,
          height: height * (isTablet ? 0.82 : 0.92),
          decoration: const BoxDecoration(color: KarisColors.paper),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Kicker('卡片'),
                          const SizedBox(height: 4),
                          Text(
                            widget.cardId == null ? '新建卡片' : '编辑卡片',
                            style: karisDisplay(fontSize: 22),
                          ),
                        ],
                      ),
                    ),
                    KarisIconButton(
                      icon: Icons.close,
                      tooltip: '关闭',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '正面',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: KarisColors.ink,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildEditor(
                        controller: _frontController,
                        focusNode: _frontFocusNode,
                        scrollController: _frontScrollController,
                        embedBuilders: embedBuilders,
                        onLatex: () => _insertLatex(_frontController),
                        onCode: () => _insertCode(_frontController),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        '反面',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: KarisColors.ink,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildEditor(
                        controller: _backController,
                        focusNode: _backFocusNode,
                        scrollController: _backScrollController,
                        embedBuilders: embedBuilders,
                        onLatex: () => _insertLatex(_backController),
                        onCode: () => _insertCode(_backController),
                      ),
                      const SizedBox(height: 16),
                      KarisPrimaryButton(
                        label: _isSaving ? '保存中...' : '保存',
                        icon: Icons.save_outlined,
                        onPressed: _isSaving ? null : _save,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
