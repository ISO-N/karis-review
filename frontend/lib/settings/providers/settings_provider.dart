import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../offline/offline_repository.dart';
import '../../offline/providers.dart';
import '../../shared/scheduling/scheduling_constants.dart';
import '../repositories/settings_repository.dart';

class SettingsState {
  final String email;
  final String refreshTime;
  final bool isLoading;
  final String? error;
  final bool isSaved;

  const SettingsState({
    this.email = '',
    this.refreshTime = SchedulingConstants.defaultRefreshTime,
    this.isLoading = false,
    this.error,
    this.isSaved = false,
  });

  SettingsState copyWith({
    String? email,
    String? refreshTime,
    bool? isLoading,
    String? error,
    bool? isSaved,
  }) {
    return SettingsState(
      email: email ?? this.email,
      refreshTime: refreshTime ?? this.refreshTime,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepository _repository;
  final OfflineRepository? offline;

  SettingsNotifier(
    this._repository, {
    this.offline,
  }) : super(const SettingsState()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    if (offline != null) {
      final meta = await offline!.getActiveSyncMeta();
      final local = meta == null ? null : await offline!.getSettings(meta.userId);
      if (local != null) {
        state = state.copyWith(
          email: local.email,
          refreshTime: local.refreshTime,
          isLoading: false,
          error: null,
        );
        return;
      }
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final settings = await _repository.getSettings();
      state = state.copyWith(
        email: settings['email'] as String? ?? '',
        refreshTime: settings['refresh_time'] as String? ?? SchedulingConstants.defaultRefreshTime,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateSettings(String refreshTime) async {
    state = state.copyWith(isLoading: true, error: null, isSaved: false);
    try {
      final settings = await _repository.updateSettings(refreshTime);
      final newRefreshTime = settings['refresh_time'] as String? ?? refreshTime;
      final meta = await offline?.getActiveSyncMeta();
      if (meta != null) {
        await offline!.saveSettings(meta.userId, meta.email ?? '', newRefreshTime);
      }
      state = state.copyWith(
        refreshTime: newRefreshTime,
        isLoading: false,
        isSaved: true,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    return SettingsNotifier(
      SettingsRepository(),
      offline: ref.watch(offlineRepositoryProvider),
    );
  },
);
