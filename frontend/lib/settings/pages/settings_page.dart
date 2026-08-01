import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/loading_widget.dart';
import '../providers/settings_provider.dart';
import '../repositories/settings_repository.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: settingsState.isLoading
          ? const LoadingWidget()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('账号',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('邮箱'),
                    subtitle: Text(settingsState.email),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('复习设置',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.schedule),
                    title: const Text('每日刷新时间'),
                    subtitle: Text(settingsState.refreshTime),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _showRefreshTimePicker(context, ref, settingsState.refreshTime),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('数据管理',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.file_download),
                        title: const Text('导出数据'),
                        subtitle: const Text('导出全部数据快照为 JSON 文件'),
                        onTap: () => _exportData(context, ref),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.file_upload),
                        title: const Text('导入数据'),
                        subtitle: const Text('从备份 JSON 文件覆盖恢复'),
                        onTap: () => _importData(context, ref),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('退出登录'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showRefreshTimePicker(BuildContext context, WidgetRef ref, String currentTime) {
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 4,
      minute: int.tryParse(parts[1]) ?? 0,
    );

    showTimePicker(
      context: context,
      initialTime: initialTime,
    ).then((time) {
      if (time != null) {
        final newTime =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
        ref.read(settingsProvider.notifier).updateSettings(newTime);
      }
    });
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final repo = SettingsRepository();
      final result = await repo.exportBackup();
      final data = result['data'];
      final jsonText = const JsonEncoder.withIndent('  ').convert(data);

      final path = await FilePicker.platform.saveFile(
        dialogTitle: '保存备份文件',
        fileName: 'karis-review-backup-${DateTime.now().millisecondsSinceEpoch}.json',
        bytes: Uint8List.fromList(utf8.encode(jsonText)),
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (!context.mounted) return;
      if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('备份已保存到 $path')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: '选择备份文件',
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) return;

    Map<String, dynamic> data;
    try {
      final text = utf8.decode(result.files.single.bytes!);
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('备份文件格式不正确');
      }
      data = decoded;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('读取备份失败: $e')),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入数据'),
        content: const Text('导入将覆盖当前所有数据，此操作不可逆。确定要继续吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定导入', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = SettingsRepository();
      final result = await repo.importBackup(data);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '数据已恢复：${result['imported_decks']} 个牌组，'
              '${result['imported_cards']} 张卡片，'
              '${result['imported_review_logs']} 条记录',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }
}