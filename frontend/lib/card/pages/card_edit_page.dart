import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/rich_card_content.dart';
import '../providers/card_provider.dart';
import '../repositories/card_repository.dart';

class CardEditPage extends ConsumerStatefulWidget {
  final String? deckId;
  final String? cardId;

  const CardEditPage({super.key, this.deckId, this.cardId});

  @override
  ConsumerState<CardEditPage> createState() => _CardEditPageState();
}

class _CardEditPageState extends ConsumerState<CardEditPage> {
  late quill.QuillController _frontController;
  late quill.QuillController _backController;
  late FocusNode _frontFocusNode;
  late FocusNode _backFocusNode;
  late ScrollController _frontScrollController;
  late ScrollController _backScrollController;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _frontController = quill.QuillController(
      document: quill.Document(),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _backController = quill.QuillController(
      document: quill.Document(),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _frontFocusNode = FocusNode();
    _backFocusNode = FocusNode();
    _frontScrollController = ScrollController();
    _backScrollController = ScrollController();
    if (widget.cardId != null) _loadCard();
  }

  Future<void> _loadCard() async {
    setState(() => _isLoading = true);
    try {
      final card = await CardRepository().getCard(widget.cardId!);
      if (mounted) {
        _setControllerContent(_frontController, card.front);
        _setControllerContent(_backController, card.back);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载卡片失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setControllerContent(quill.QuillController controller, String content) {
    final trimmed = content.trim();
    if (trimmed.startsWith('[')) {
      try {
        final doc = quill.Document.fromJson(jsonDecode(trimmed) as List<dynamic>);
        if (identical(controller, _frontController)) {
          _frontController.dispose();
          _frontController = quill.QuillController(
            document: doc,
            selection: const TextSelection.collapsed(offset: 0),
          );
        } else {
          _backController.dispose();
          _backController = quill.QuillController(
            document: doc,
            selection: const TextSelection.collapsed(offset: 0),
          );
        }
        return;
      } catch (_) {}
    }
    if (content.isNotEmpty) {
      controller.document.insert(0, content);
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正面和反面内容不能为空')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = CardRepository();
      if (widget.cardId != null) {
        await repo.updateCard(widget.cardId!, front, back);
      } else {
        await repo.createCard(widget.deckId!, front, back);
      }

      if (mounted) {
        if (widget.deckId != null) {
          ref.read(cardListProvider(widget.deckId!).notifier).loadCards();
          context.go('/decks/${widget.deckId}/cards');
        } else {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
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
                decoration: const InputDecoration(labelText: '语言', hintText: 'dart, java, python...'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: '代码',
                  border: OutlineInputBorder(),
                  hintText: '粘贴代码...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                ctx,
                (languageController.text.trim(), codeController.text),
              ),
              child: const Text('插入'),
            ),
          ],
        );
      },
    );
    if (result == null || result.$2.trim().isEmpty) return;
    final index = controller.selection.baseOffset;
    controller.document.insert(index, CodeEmbed(result.$1.isEmpty ? 'text' : result.$1, result.$2));
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
    final embedBuilders = const [LatexEmbedBuilder(), CodeEmbedBuilder()];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cardId != null ? '编辑卡片' : '新建卡片'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('保存'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('正面', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildEditor(
                    controller: _frontController,
                    focusNode: _frontFocusNode,
                    scrollController: _frontScrollController,
                    embedBuilders: embedBuilders,
                    onLatex: () => _insertLatex(_frontController),
                    onCode: () => _insertCode(_frontController),
                  ),
                  const SizedBox(height: 24),
                  const Text('反面', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '工具栏支持粗体、斜体、标题、列表、代码块。\n'
                      '点击 ∑ 插入 LaTeX 数学公式，点击 </> 插入带语法高亮的代码块。',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                ],
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
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
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
          Container(
            constraints: const BoxConstraints(minHeight: 140),
            padding: const EdgeInsets.symmetric(horizontal: 8),
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