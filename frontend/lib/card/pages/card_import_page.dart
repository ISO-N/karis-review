import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/widgets/adaptive_scaffold.dart';
import '../../shared/widgets/app_semantics.dart';
import '../../shared/widgets/rich_card_content.dart';
import '../../shared/widgets/section_widgets.dart';
import '../models/card_import.dart';
import '../repositories/card_repository.dart';
import 'card_editor_page.dart';

const String _importSampleJson = '''
[
  {
    "front": "间隔重复是什么？",
    "back": "按遗忘曲线在合适时间安排复习"
  }
]''';

class CardImportPage extends StatefulWidget {
  final String deckId;
  final CardRepository repository;
  final ValueChanged<int>? onImported;

  CardImportPage({
    super.key,
    required this.deckId,
    CardRepository? repository,
    this.onImported,
  }) : repository = repository ?? CardRepository();

  @override
  State<CardImportPage> createState() => _CardImportPageState();
}

class _CardImportPageState extends State<CardImportPage> {
  CardRepository get _repository => widget.repository;
  final TextEditingController _jsonController = TextEditingController();
  final List<CardImportPreviewItem> _items = [];

  bool _usePaste = true;
  bool _showPreview = false;
  bool _parsing = false;
  bool _importing = false;
  String? _fileName;
  String? _fileContent;
  String? _error;
  String? _importError;
  bool _hasEdits = false;

  int get _validCount => _items.where((item) => item.valid).length;
  int get _invalidCount => _items.length - _validCount;

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasEdits || _importing,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _importing) return;
        _confirmAndClose();
      },
      child: Scaffold(
        backgroundColor: KarisColors.paper,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _showPreview
                        ? _buildPreviewBody()
                        : _buildInputBody(),
                  ),
                  if (_showPreview) _buildPreviewFooter(),
                ],
              ),
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
            tooltip: _showPreview ? '返回输入' : '返回',
            onPressed: _parsing || _importing
                ? null
                : (_showPreview ? _backToSource : _closePage),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Kicker('卡片'),
                const SizedBox(height: 4),
                KarisHeading(
                  child: Text(
                    _showPreview ? '导入预览' : '快捷导入',
                    style: karisDisplay(fontSize: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _SourceButton(
                  label: '粘贴 JSON',
                  icon: Icons.content_paste_outlined,
                  active: _usePaste,
                  onPressed: () {
                    setState(() {
                      _usePaste = true;
                      _error = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SourceButton(
                  label: '选择文件',
                  icon: Icons.folder_open_outlined,
                  active: !_usePaste,
                  onPressed: _pickFile,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_usePaste)
            TextField(
              controller: _jsonController,
              minLines: 12,
              maxLines: 14,
              keyboardType: TextInputType.multiline,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => _markEdits(),
              style: karisMono(fontSize: 12),
              decoration: const InputDecoration(
                labelText: 'JSON 数组',
                alignLabelWithHint: true,
                hintText:
                    '[\n  {\n    "front": "正面",\n    "back": "反面"\n  }\n]',
              ),
            )
          else
            _buildFileStatus(),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _buildErrorBox(_error!),
          ],
          const SizedBox(height: 12),
          _buildFormatGuide(),
          const SizedBox(height: 20),
          KarisPrimaryButton(
            label: _parsing ? '解析中…' : '解析并预览',
            icon: Icons.fact_check_outlined,
            onPressed: _parsing ? null : () => _parse(),
          ),
        ],
      ),
    );
  }

  Future<void> _copyFormatExample() async {
    await Clipboard.setData(ClipboardData(text: _importSampleJson.trim()));
    if (!mounted) return;
    announceMessage(context, '示例 JSON 已复制');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('示例 JSON 已复制')));
  }

  Widget _buildFormatGuide() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KarisColors.surface,
        border: Border.all(color: KarisColors.hairline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'JSON 格式',
                  style: TextStyle(
                    color: KarisColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _copyFormatExample,
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('复制示例'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  backgroundColor: KarisColors.paper,
                  foregroundColor: KarisColors.jade,
                  side: const BorderSide(color: KarisColors.hairline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: KarisColors.paper,
              border: Border.all(color: KarisColors.hairline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                _importSampleJson.trim(),
                style: karisMono(fontSize: 12),
                softWrap: false,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '格式要点',
            style: TextStyle(
              color: KarisColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          const _FormatRule(
            icon: Icons.data_object_rounded,
            text: '顶层必须是 JSON 数组，单次最多 1000 张',
          ),
          const _FormatRule(
            icon: Icons.label_outline_rounded,
            text: '每张卡片包含 front 和 back，两个字段都必须是非空字符串',
          ),
          const _FormatRule(
            icon: Icons.text_fields_rounded,
            text: '正文支持普通文本、轻量 Markdown，以及卡片编辑器生成的 Delta JSON',
          ),
          const _FormatRule(
            icon: Icons.info_outline_rounded,
            text: '未知字段会被忽略；粘贴内容或文件最大 2MB',
          ),
        ],
      ),
    );
  }

  Widget _buildFileStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KarisColors.surface,
        border: Border.all(color: KarisColors.hairline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _fileName == null
                ? Icons.description_outlined
                : Icons.check_circle_outline,
            size: 22,
            color: _fileName == null ? KarisColors.stone : KarisColors.jade,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fileName ?? '未选择 JSON 文件',
                  style: const TextStyle(
                    color: KarisColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _fileContent == null
                      ? '请选择一个 .json 文件，读取后会自动解析'
                      : '已读取 ${_fileContent!.length} 个字符，可重新选择',
                  style: const TextStyle(
                    color: KarisColors.stone,
                    fontSize: 12,
                    height: 1.5,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryBadge(
                label: '总数',
                value: '${_items.length}',
                color: KarisColors.ink,
              ),
              _SummaryBadge(
                label: '有效',
                value: '$_validCount',
                color: KarisColors.jade,
              ),
              if (_invalidCount > 0)
                _SummaryBadge(
                  label: '无效',
                  value: '$_invalidCount',
                  color: KarisColors.cinnabar,
                ),
            ],
          ),
        ),
        Expanded(
          child: _items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('没有可预览的卡片')),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _buildPreviewItem(index, _items[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildPreviewItem(int index, CardImportPreviewItem item) {
    final invalid = !item.valid;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KarisColors.surface,
        border: Border.all(
          color: invalid
              ? KarisColors.cinnabar.withValues(alpha: 0.55)
              : KarisColors.hairline,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (invalid && item.message != null)
                  Text(
                    '${index + 1} · ${item.message}',
                    style: const TextStyle(
                      color: KarisColors.cinnabar,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                if (invalid && item.message != null) const SizedBox(height: 6),
                if (item.front.trim().isNotEmpty)
                  RichCardContent(
                    content: item.front,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: KarisColors.ink,
                      height: 1.5,
                      letterSpacing: 0,
                    ),
                    maxLines: 3,
                  )
                else
                  const Text(
                    '正面未填写',
                    style: TextStyle(
                      color: KarisColors.stone,
                      fontSize: 13,
                      letterSpacing: 0,
                    ),
                  ),
                const SizedBox(height: 10),
                const Text(
                  '反面',
                  style: TextStyle(
                    color: KarisColors.stone,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                if (item.back.trim().isNotEmpty)
                  RichCardContent(
                    content: item.back,
                    style: const TextStyle(
                      fontSize: 13,
                      color: KarisColors.stone,
                      height: 1.5,
                      letterSpacing: 0,
                    ),
                    maxLines: 3,
                  )
                else
                  const Text(
                    '反面未填写',
                    style: TextStyle(
                      color: KarisColors.stone,
                      fontSize: 13,
                      letterSpacing: 0,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              IconButton(
                onPressed: () => _editItem(index),
                tooltip: '编辑',
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: KarisColors.ink,
                style: IconButton.styleFrom(
                  minimumSize: const Size(36, 36),
                  backgroundColor: KarisColors.paper,
                  side: const BorderSide(color: KarisColors.hairline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              IconButton(
                onPressed: () => _deleteItem(index),
                tooltip: '删除',
                icon: const Icon(Icons.delete_outline, size: 18),
                color: KarisColors.cinnabar,
                style: IconButton.styleFrom(
                  minimumSize: const Size(36, 36),
                  backgroundColor: KarisColors.cinnabarSoft,
                  side: const BorderSide(
                    color: KarisColors.cinnabar,
                    width: 0.6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: KarisColors.paper,
        border: Border(top: BorderSide(color: KarisColors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_invalidCount > 0)
              const Text(
                '还有无效卡片，请修复或删除后再导入',
                style: TextStyle(
                  color: KarisColors.cinnabar,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            if (_importError != null) ...[
              const SizedBox(height: 8),
              _buildErrorBox(_importError!),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: KarisSecondaryButton(
                    label: '返回',
                    icon: Icons.arrow_back,
                    onPressed: _importing ? null : _backToSource,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: KarisPrimaryButton(
                    label: _importing
                        ? '导入中…'
                        : _validCount > 0
                        ? '导入 $_validCount 张卡片'
                        : '导入卡片',
                    icon: Icons.file_upload_outlined,
                    onPressed:
                        _validCount > 0 && _invalidCount == 0 && !_importing
                        ? _import
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KarisColors.cinnabarSoft,
        border: Border.all(color: KarisColors.cinnabar),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: KarisColors.cinnabar,
          fontSize: 13,
          height: 1.5,
          letterSpacing: 0,
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: '选择 JSON 文件',
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.bytes == null) {
      setState(() => _error = '无法读取文件内容');
      return;
    }

    try {
      final content = utf8.decode(file.bytes!);
      setState(() {
        _usePaste = false;
        _fileName = file.name;
        _fileContent = content;
        _error = null;
      });
      await _parse(content);
    } catch (e) {
      if (mounted) {
        setState(() => _error = '读取文件失败，请确认文件为 UTF-8 JSON 后重试');
      }
    }
  }

  Future<void> _parse([String? explicitContent]) async {
    final content =
        explicitContent ??
        (_usePaste ? _jsonController.text : _fileContent ?? '');
    if (content.trim().isEmpty) {
      setState(() => _error = '请先粘贴 JSON 数组或选择文件');
      return;
    }

    setState(() {
      _parsing = true;
      _error = null;
      _importError = null;
    });

    try {
      final data = await _repository.previewCardImport(widget.deckId, content);
      final rawCards = data['cards'] as List<dynamic>? ?? [];
      final items = rawCards
          .map(
            (item) =>
                CardImportPreviewItem.fromJson(item as Map<String, dynamic>),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(items);
        _showPreview = true;
        _parsing = false;
        _hasEdits = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _parsing = false;
        _error = '解析失败，请检查 JSON 格式后重试';
      });
    }
  }

  Future<void> _import() async {
    if (_validCount == 0 || _invalidCount > 0 || _importing) return;

    setState(() {
      _importing = true;
      _importError = null;
    });

    try {
      final cards = _items
          .where((item) => item.valid)
          .map((item) => {'front': item.front, 'back': item.back})
          .toList();
      final result = await _repository.importCards(widget.deckId, cards);
      final imported =
          (result['imported_cards'] as num?)?.toInt() ?? _validCount;
      widget.onImported?.call(imported);
      if (mounted) Navigator.pop(context, imported);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _importing = false;
        _importError = '导入失败，请检查网络连接后重试';
      });
    }
  }

  Future<void> _editItem(int index) async {
    final result = await context.push<(String, String)>(
      '/decks/${widget.deckId}/cards/editor',
      extra: CardEditorArgs(
        deckId: widget.deckId,
        initialFront: _items[index].front,
        initialBack: _items[index].back,
        title: '编辑导入卡片',
        localOnly: true,
      ),
    );
    if (result == null || !mounted) return;
    _applyEdit(index, result.$1, result.$2);
  }

  void _markEdits() {
    if (_hasEdits) return;
    setState(() => _hasEdits = true);
  }

  void _applyEdit(int index, String front, String back) {
    final messages = <String>[];
    if (front.trim().isEmpty) messages.add('正面内容不能为空');
    if (back.trim().isEmpty) messages.add('反面内容不能为空');
    setState(() {
      _items[index] = _items[index].copyWith(
        front: front,
        back: back,
        valid: messages.isEmpty,
        message: messages.isEmpty ? null : messages.join('，'),
        clearMessage: messages.isEmpty,
      );
      _hasEdits = true;
    });
  }

  void _deleteItem(int index) {
    setState(() {
      _items.removeAt(index);
      _hasEdits = true;
    });
  }

  Future<bool> _confirmDiscard() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('放弃未保存内容'),
        content: const Text('当前修改尚未保存，确定要离开吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('继续编辑'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('放弃修改'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  Future<void> _backToSource() async {
    if (_showPreview && _hasEdits) {
      final leave = await _confirmDiscard();
      if (leave != true || !mounted) return;
      setState(() => _hasEdits = false);
    }
    setState(() {
      _showPreview = false;
      _importError = null;
    });
  }

  Future<void> _confirmAndClose() async {
    if (_hasEdits) {
      final leave = await _confirmDiscard();
      if (leave != true || !mounted) return;
    }
    setState(() => _hasEdits = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _popOrGo();
    });
  }

  void _closePage() {
    _confirmAndClose();
  }

  void _popOrGo() {
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    } else {
      context.go('/decks/${widget.deckId}/cards');
    }
  }
}

class _SourceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onPressed;

  const _SourceButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        backgroundColor: active ? KarisColors.jadeSoft : KarisColors.surface,
        foregroundColor: active ? KarisColors.jade : KarisColors.ink,
        side: BorderSide(
          color: active ? KarisColors.jade : KarisColors.hairline,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _FormatRule extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FormatRule({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: KarisColors.jade),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: KarisColors.stone,
                fontSize: 12,
                height: 1.5,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: KarisColors.surface,
        border: Border.all(color: KarisColors.hairline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: KarisColors.stone,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(width: 8),
          Text(value, style: karisMono(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}
