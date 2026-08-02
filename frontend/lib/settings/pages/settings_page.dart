import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../deck/providers/deck_provider.dart';
import '../../offline/providers.dart';
import '../../shared/widgets/adaptive_scaffold.dart';
import '../../shared/widgets/app_semantics.dart';
import '../../shared/widgets/section_widgets.dart';
import '../../shared/widgets/settings_action_tile.dart';
import '../../stats/providers/stats_provider.dart';
import '../../sync/providers.dart';
import '../providers/settings_provider.dart';
import '../repositories/settings_repository.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    return AdaptiveAppScaffold(
      current: KarisNavItem.settings,
      onSelect: (item) => _go(item, context),
      body: RefreshIndicator(
        onRefresh: () => ref.read(settingsProvider.notifier).loadSettings(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20,
            isTablet ? 132 : 20,
            20,
            isTablet ? 24 : 132,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SettingsHeader(),
                  const SizedBox(height: 20),
                  if (settingsState.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else ...[
                    _AccountBlock(settingsState: settingsState),
                    const SizedBox(height: 22),
                    if (isTablet)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _ReviewSettingsBlock(
                              settingsState: settingsState,
                              ref: ref,
                            ),
                          ),
                          const SizedBox(width: 28),
                          Expanded(
                            child: _DataBlock(context: context, ref: ref),
                          ),
                        ],
                      )
                    else ...[
                      _ReviewSettingsBlock(
                        settingsState: settingsState,
                        ref: ref,
                      ),
                      const SizedBox(height: 22),
                      _DataBlock(context: context, ref: ref),
                    ],
                    const SizedBox(height: 22),
                    _LogoutButton(ref: ref),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _go(KarisNavItem item, BuildContext context) {
    switch (item) {
      case KarisNavItem.home:
        context.go('/home');
      case KarisNavItem.decks:
        context.go('/decks');
      case KarisNavItem.stats:
        context.go('/stats');
      case KarisNavItem.settings:
        context.go('/settings');
    }
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Kicker('SETTINGS'),
              const SizedBox(height: 7),
              KarisHeading(
                child: Text('设置', style: karisDisplay(fontSize: 27)),
              ),
            ],
          ),
        ),
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: KarisColors.surface,
            border: Border.all(color: KarisColors.hairline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.settings, size: 18, color: KarisColors.jade),
        ),
      ],
    );
  }
}

class _AccountBlock extends StatelessWidget {
  final dynamic settingsState;

  const _AccountBlock({required this.settingsState});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '账号'),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 58),
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: KarisColors.surface,
            border: Border.all(color: KarisColors.hairline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const _SettingIcon(icon: Icons.mail_outline),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '邮箱',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: KarisColors.ink,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      settingsState.email,
                      style: karisMono(fontSize: 11, color: KarisColors.stone),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewSettingsBlock extends StatelessWidget {
  final dynamic settingsState;
  final WidgetRef ref;

  const _ReviewSettingsBlock({required this.settingsState, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '复习设置'),
        SettingsActionTile(
          icon: Icons.schedule_outlined,
          title: '每日刷新时间',
          subtitle: '过此时间后计入新的一天',
          onTap: () => _pickTime(context),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: KarisColors.paper,
              border: Border.all(color: KarisColors.hairline),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              settingsState.refreshTime.length >= 8
                  ? settingsState.refreshTime.substring(0, 5)
                  : settingsState.refreshTime,
              style: karisMono(fontSize: 11, color: KarisColors.ink),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    final parts = settingsState.refreshTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 4,
      minute: int.tryParse(parts[1]) ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final value =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
    await ref.read(settingsProvider.notifier).updateSettings(value);
  }
}

class _DataBlock extends StatelessWidget {
  final BuildContext context;
  final WidgetRef ref;

  const _DataBlock({required this.context, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '数据管理'),
        SettingsActionTile(
          icon: Icons.file_download_outlined,
          title: '导出数据',
          subtitle: '保存全部牌组、卡片与复习记录',
          onTap: () => _export(context, ref),
        ),
        SettingsActionTile(
          icon: Icons.file_upload_outlined,
          title: '导入数据',
          subtitle: '从备份文件覆盖恢复',
          danger: true,
          onTap: () => _import(context, ref),
        ),
        SettingsActionTile(
          icon: Icons.cloud_sync_outlined,
          title: '以服务器为准',
          subtitle: '丢弃待同步评分并重新拉取服务器数据',
          danger: true,
          onTap: () => _forceServer(context, ref),
        ),
      ],
    );
  }

  Future<void> _forceServer(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('以服务器为准'),
        content: const Text('这会丢弃所有未同步的离线评分，并用服务器数据覆盖本地。确定继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: KarisColors.cinnabar,
              foregroundColor: KarisColors.surface,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('确定覆盖'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final meta = await ref.read(offlineRepositoryProvider).getActiveSyncMeta();
      if (meta != null) {
        await ref.read(syncServiceProvider).forceServerAuthoritative(userId: meta.userId);
        ref.invalidate(deckListProvider);
        ref.invalidate(statsProvider);
        ref.invalidate(settingsProvider);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('同步失败，请检查网络后重试')),
        );
      }
    }
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    try {
      final result = await SettingsRepository().exportBackup();
      final data = result['data'];
      final jsonText = const JsonEncoder.withIndent('  ').convert(data);
      await FilePicker.platform.saveFile(
        dialogTitle: '保存备份文件',
        fileName:
            'karis-review-backup-${DateTime.now().millisecondsSinceEpoch}.json',
        bytes: Uint8List.fromList(utf8.encode(jsonText)),
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
    } catch (e) {
      if (context.mounted) {
        announceMessage(context, '导出失败，请检查网络后重试');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导出失败，请检查网络后重试')));
      }
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: '选择备份文件',
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(utf8.decode(result.files.single.bytes!));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('备份文件格式不正确');
      }
      data = decoded;
    } catch (e) {
      if (context.mounted) {
        announceMessage(context, '读取备份失败，请确认文件格式正确后重试');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('读取备份失败，请确认文件格式正确后重试')));
      }
      return;
    }

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('导入数据'),
        content: const Text('导入将覆盖当前所有数据，此操作不可逆。确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: KarisColors.cinnabar,
              foregroundColor: KarisColors.surface,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('确定导入'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final result = await SettingsRepository().importBackup(data);
      ref.invalidate(deckListProvider);
      ref.invalidate(statsProvider);
      ref.invalidate(settingsProvider);
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
        announceMessage(context, '导入失败，请检查网络或备份文件后重试');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导入失败，请检查网络或备份文件后重试')));
      }
    }
  }
}

class _LogoutButton extends StatelessWidget {
  final WidgetRef ref;

  const _LogoutButton({required this.ref});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        await ref.read(authProvider.notifier).logout();
        if (context.mounted) context.go('/login');
      },
      icon: const Icon(Icons.logout, size: 17),
      label: const Text('退出登录'),
      style: OutlinedButton.styleFrom(
        foregroundColor: KarisColors.cinnabar,
        side: BorderSide(color: KarisColors.cinnabar.withValues(alpha: 0.45)),
        minimumSize: const Size(double.infinity, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _SettingIcon extends StatelessWidget {
  final IconData icon;

  const _SettingIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: KarisColors.jadeSoft,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(icon, size: 17, color: KarisColors.jade),
    );
  }
}
