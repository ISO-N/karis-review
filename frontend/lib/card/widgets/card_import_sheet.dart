import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/widgets/adaptive_scaffold.dart';
import '../../shared/widgets/rich_card_content.dart';
import '../../shared/widgets/section_widgets.dart';
import '../models/card_import.dart';
import '../repositories/card_repository.dart';
import 'card_editor_sheet.dart';

class CardImportSheet extends StatefulWidget {
  final String deckId;
  final ValueChanged<int>? onImported;

  const CardImportSheet({
    super.key,
    required this.deckId,
    this.onImported,
  });

  @override
  State<CardImportSheet> createState() => _CardImportSheetState();
}

class _CardImportSheetState extends State<CardImportSheet> {
  final CardRepository _repository = CardRepository();
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

  int get _validCount => _items.where((item) => item.valid).length;
  int get _invalidCount => _items.length - _validCount;

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    return SafeArea(
      top: false,
      child: Center(
        child: Container(
          width: isTablet ? 760 : double.infinity,
          height: height * (isTablet ? 0.9 : 0.96),
          decoration: const BoxDecoration(color: KarisColors.paper),
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
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
      child: Row(
        children: [
          if (_showPreview)
            KarisIconButton(
              icon: Icons.arrow_back,
              tooltip: '返回',
              onPressed:
                  _parsing || _importing ? null : () => _backToSource(),
            )
          else
            const SizedBox(width: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Kicker('卡片'),
                const SizedBox(height: 4),
                Text(
                  _showPreview ? '导入预览' : '快捷导入',
                  style: karisDisplay(fontSize: 22),
                ),
              ],
            ),
          ),
          KarisIconButton(
            icon: Icons.close,
            tooltip: '关闭',
            onPressed: _parsing || _importing ? null : () => Navigator.pop(context),
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
              style: karisMono(fontSize: 12),
              decoration: const InputDecoration(
                labelText: 'JSON 数组',
                alignLabelWithHint: true,
                hintText: '[\n  {\n    "front": "正面",\n    "back": "反面"\n  }\n]',
              ),
            )
          else
            _buildFileStatus(),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _buildErrorBox(_error!),
          ],
          const SizedBox(height: 20),
          KarisPrimaryButton(
            label: _parsing ? '解析中...' : '解析并预览',
            icon: Icons.fact_check_outlined,
            onPressed: _parsing ? null : () => _parse(),
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
                        ? '导入中...'
                        : _validCount > 0
                        ? '导入 $_validCount 张卡片'
                        : '导入卡片',
                    icon: Icons.file_upload_outlined,
                    onPressed:
                        _validCount > 0 &&
                            _invalidCount == 0 &&
                            !_importing
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
        setState(() => _error = '读取文件失败: ${_errorMessage(e)}');
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
            (item) => CardImportPreviewItem.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(items);
        _showPreview = true;
        _parsing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _parsing = false;
        _error = _errorMessage(e);
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
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _importing = false;
        _importError = _errorMessage(e);
      });
    }
  }

  void _editItem(int index) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CardEditorSheet(
        deckId: widget.deckId,
        initialFront: _items[index].front,
        initialBack: _items[index].back,
        title: '编辑导入卡片',
        onLocalSave: (content) {
          if (mounted) _applyEdit(index, content.$1, content.$2);
        },
      ),
    );
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
    });
  }

  void _deleteItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _backToSource() {
    setState(() {
      _showPreview = false;
      _importError = null;
    });
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
    }
    return error.toString();
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
          Text(
            value,
            style: karisMono(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }
}
