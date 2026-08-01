import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/settings_repository.dart';

class SettingsState {
  final String email;
  final String refreshTime;
  final bool isLoading;
  final String? error;
  final bool isSaved;

  const SettingsState({
    this.email = '',
    this.refreshTime = '04:00:00',
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

  SettingsNotifier(this._repository) : super(const SettingsState()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final settings = await _repository.getSettings();
      state = state.copyWith(
        email: settings['email'] as String? ?? '',
        refreshTime: settings['refresh_time'] as String? ?? '04:00:00',
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
      state = state.copyWith(
        refreshTime: settings['refresh_time'] as String? ?? refreshTime,
        isLoading: false,
        isSaved: true,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(SettingsRepository());
});