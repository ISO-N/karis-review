import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../offline/providers.dart';
import '../../shared/navigation/tab_navigation.dart';
import '../../shared/providers/data_refresh_provider.dart';
import '../../shared/widgets/adaptive_scaffold.dart';
import '../../shared/widgets/app_feedback.dart';
import '../../shared/widgets/app_semantics.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/section_widgets.dart';
import '../../shared/widgets/settings_action_tile.dart';
import '../../sync/providers.dart';
import '../../tts/tts_provider.dart';
import '../providers/settings_provider.dart';
import '../repositories/settings_repository.dart';

import '../../l10n/app_localizations.dart';
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    return AdaptiveAppScaffold(
      current: KarisNavItem.settings,
      onSelect: (item) => goToTab(context, ref, item),
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
                  SizedBox(height: 20),
                  if (settingsState.isLoading)
                    const LoadingWidget()
                  else ...[
                    _AccountBlock(settingsState: settingsState, ref: ref),
                    SizedBox(height: 22),
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
                          SizedBox(width: 28),
                          Expanded(
                            child: Column(
                              children: [
                                _TtsSettingsBlock(),
                                SizedBox(height: 22),
                                _DataBlock(context: context, ref: ref),
                              ],
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _ReviewSettingsBlock(
                        settingsState: settingsState,
                        ref: ref,
                      ),
                      SizedBox(height: 22),
                      _TtsSettingsBlock(),
                      SizedBox(height: 22),
                      _DataBlock(context: context, ref: ref),
                    ],
                    SizedBox(height: 22),
                    _DiagnosticsBlock(context: context, ref: ref),
                    SizedBox(height: 22),
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
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
      final l10n = KarisReviewLocalizations.of(context)!;
      final colors = context.karisColors;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Kicker('SETTINGS'),
              SizedBox(height: 7),
              KarisHeading(
                child: Text(l10n.settingsTitle, style: karisDisplay(fontSize: 27)),
              ),
            ],
          ),
        ),
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.hairline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.settings, size: 18, color: colors.jade),
        ),
      ],
    );
  }
}

class _AccountBlock extends StatelessWidget {
  final dynamic settingsState;
  final WidgetRef ref;

  const _AccountBlock({required this.settingsState, required this.ref});

  @override
  Widget build(BuildContext context) {
      final l10n = KarisReviewLocalizations.of(context)!;
      final colors = context.karisColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.settingsAccount),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 58),
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.hairline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const _SettingIcon(icon: Icons.mail_outline),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
          l10n.settingsEmail,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.ink,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      settingsState.email,
                      style: karisMono(fontSize: 11, color: colors.stone),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
        SettingsActionTile(
          icon: Icons.password_outlined,
          title: l10n.settingsChangePassword,
          subtitle: l10n.settingsChangePasswordSubtitle,
          onTap: () => _changePassword(context, ref),
        ),
      ],
    );
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final l10n = KarisReviewLocalizations.of(context)!;
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var obscure = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(l10n.settingsChangePasswordTitle),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentController,
                    obscureText: obscure,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: l10n.settingsCurrentPasswordLabel,
                      prefixIcon: const Icon(Icons.lock_outline, size: 18),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? l10n.authPasswordLabel
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newController,
                    obscureText: obscure,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: l10n.settingsNewPasswordLabel,
                      prefixIcon: const Icon(Icons.lock_outline, size: 18),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return l10n.settingsNewPasswordShort;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: l10n.settingsConfirmPasswordLabel,
                      prefixIcon: const Icon(Icons.lock_outline, size: 18),
                    ),
                    validator: (value) =>
                        (value != newController.text)
                            ? l10n.settingsPasswordMismatch
                            : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.settingsForceServerCancel),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: Text(l10n.settingsChangePasswordConfirm),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    final notifier = ref.read(authProvider.notifier);
    await notifier.changePassword(
      currentController.text,
      newController.text,
    );
    if (!context.mounted) return;
    // 修改成功会触发登出，此处直接回登录页并提示
    if (context.mounted) {
      context.go('/login');
      showKarisFeedback(
        context,
        tone: KarisFeedbackTone.success,
        title: l10n.settingsChangePasswordSuccess,
      );
    }
  }
}

class _ReviewSettingsBlock extends StatelessWidget {
  final dynamic settingsState;
  final WidgetRef ref;

  const _ReviewSettingsBlock({required this.settingsState, required this.ref});

  @override
  Widget build(BuildContext context) {
      final l10n = KarisReviewLocalizations.of(context)!;
      final colors = context.karisColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.settingsReview),
        SettingsActionTile(
          icon: Icons.schedule_outlined,
          title: l10n.settingsRefreshTime,
          subtitle: l10n.settingsRefreshSubtitle,
          onTap: () => _pickTime(context),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: colors.paper,
              border: Border.all(color: colors.hairline),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              settingsState.refreshTime.length >= 8
                  ? settingsState.refreshTime.substring(0, 5)
                  : settingsState.refreshTime,
              style: karisMono(fontSize: 11, color: colors.ink),
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
    final controller = ref.read(dataRefreshControllerProvider);
    controller.notifyLocalChanged();
    await controller.armDailyRefresh();
  }
}

/// 朗读设置块：开关 + 语速。偏好存本地 SharedPreferences，不进后端。
class _TtsSettingsBlock extends ConsumerWidget {
  const _TtsSettingsBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.karisColors;
    final tts = ref.watch(ttsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: '朗读'),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.hairline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              SwitchListTile(
                value: tts.enabled,
                onChanged: tts.available
                    ? (v) => ref.read(ttsProvider.notifier).setEnabled(v)
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                secondary: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colors.jadeSoft,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(
                    Icons.volume_up_outlined,
                    size: 17,
                    color: colors.jade,
                  ),
                ),
                title: const Text(
                  '朗读卡片内容',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  tts.available
                      ? '复习页点喇叭或按 V 键朗读'
                      : '未检测到系统语音引擎（Linux 需安装 speech-dispatcher）',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              if (tts.enabled && tts.available) ...[
                Divider(height: 1, indent: 14, endIndent: 14),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: Row(
                    children: [
                      const Text(
                        '语速',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: tts.rate,
                          min: 0.5,
                          max: 1.5,
                          divisions: 10,
                          label: '${tts.rate.toStringAsFixed(1)}x',
                          onChanged: (v) =>
                              ref.read(ttsProvider.notifier).setRate(v),
                        ),
                      ),
                      Text(
                        '${tts.rate.toStringAsFixed(1)}x',
                        style: karisMono(
                          fontSize: 11,
                          color: colors.stone,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DataBlock extends StatelessWidget {
  final BuildContext context;
  final WidgetRef ref;

  KarisReviewLocalizations get l10n => KarisReviewLocalizations.of(context)!;

  const _DataBlock({required this.context, required this.ref});

  @override
  Widget build(BuildContext context) {
      final l10n = KarisReviewLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.settingsData),
        SettingsActionTile(
          icon: Icons.file_download_outlined,
          title: l10n.settingsExport,
          subtitle: l10n.settingsExportSubtitle,
          onTap: () => _export(context, ref),
        ),
        SettingsActionTile(
          icon: Icons.file_upload_outlined,
          title: l10n.settingsImport,
          subtitle: l10n.settingsImportSubtitle,
          danger: true,
          onTap: () => _import(context, ref),
        ),
        SettingsActionTile(
          icon: Icons.cloud_sync_outlined,
          title: l10n.settingsForceServer,
          subtitle: l10n.settingsForceServerSubtitle,
          danger: true,
          onTap: () => _forceServer(context, ref),
        ),
      ],
    );
  }

  Future<void> _forceServer(BuildContext context, WidgetRef ref) async {
    final colors = context.karisColors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsForceServer),
        content: Text(l10n.settingsForceServerContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.settingsForceServerCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.cinnabar,
              foregroundColor: colors.surface,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.settingsForceServerConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final meta = await ref
          .read(offlineRepositoryProvider)
          .getActiveSyncMeta();
      if (meta != null) {
        await ref
            .read(syncServiceProvider)
            .forceServerAuthoritative(userId: meta.userId);
        final controller = ref.read(dataRefreshControllerProvider);
        await controller.refreshFromServer(force: true);
        await controller.armDailyRefresh();
        ref.invalidate(settingsProvider);
      }
    } catch (_) {
      if (context.mounted) {
        showKarisFeedback(
          context,
          tone: KarisFeedbackTone.error,
          title: l10n.settingsSyncFail,
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
        announceMessage(context, l10n.settingsExportFail);
        showKarisFeedback(
          context,
          tone: KarisFeedbackTone.error,
          title: l10n.settingsExportFail,
        );
      }
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final colors = context.karisColors;
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
        announceMessage(context, l10n.settingsImportReadFail);
        showKarisFeedback(
          context,
          tone: KarisFeedbackTone.error,
          title: l10n.settingsImportReadFail,
        );
      }
      return;
    }

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsImport),
        content: Text(l10n.settingsImportContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.settingsForceServerCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.cinnabar,
              foregroundColor: colors.surface,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.settingsImportConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final result = await SettingsRepository().importBackup(data);
      final controller = ref.read(dataRefreshControllerProvider);
      await controller.refreshFromServer(force: true);
      await controller.armDailyRefresh();
      ref.invalidate(settingsProvider);
      if (context.mounted) {
        showKarisFeedback(
          context,
          tone: KarisFeedbackTone.success,
          title: '数据已恢复：${result['imported_decks']} 个卡组，'
              '${result['imported_cards']} 张卡片，'
              '${result['imported_review_logs']} 条记录',
        );
      }
    } catch (e) {
      if (context.mounted) {
        announceMessage(context, l10n.settingsImportFail);
        showKarisFeedback(
          context,
          tone: KarisFeedbackTone.error,
          title: l10n.settingsImportFail,
        );
      }
    }
  }
}

class _DiagnosticsBlock extends StatelessWidget {
  final BuildContext context;
  final WidgetRef ref;

  KarisReviewLocalizations get l10n => KarisReviewLocalizations.of(context)!;

  const _DiagnosticsBlock({required this.context, required this.ref});

  @override
  Widget build(BuildContext context) {
      final l10n = KarisReviewLocalizations.of(context)!;
    // 最近一次评分同步结果（架构评审 F2 消费点）：冲突/缺失数不再是丢弃的返回值。
    final outcome = ref.watch(syncServiceProvider).lastSyncOutcome;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.logDiagnostics),
        SettingsActionTile(
          icon: Icons.terminal_outlined,
          title: l10n.settingsLogs,
          subtitle: l10n.settingsLogsSubtitle,
          onTap: () => context.go('/settings/logs'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Text(
            '最近同步：已同步 ${outcome.synced} · 冲突 ${outcome.conflicts} · 缺失 ${outcome.missing}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final WidgetRef ref;

  const _LogoutButton({required this.ref});

  @override
  Widget build(BuildContext context) {
      final l10n = KarisReviewLocalizations.of(context)!;
      final colors = context.karisColors;
    return OutlinedButton.icon(
      onPressed: () async {
        await ref.read(authProvider.notifier).logout();
        if (context.mounted) context.go('/login');
      },
      icon: const Icon(Icons.logout, size: 17),
      label: Text(l10n.settingsLogout),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.cinnabar,
        side: BorderSide(color: colors.cinnabar.withValues(alpha: 0.45)),
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
    final colors = context.karisColors;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: colors.jadeSoft,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(icon, size: 17, color: colors.jade),
    );
  }
}
