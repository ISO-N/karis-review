import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../offline/providers.dart';
import '../../shared/api/api_client.dart';
import '../../sync/providers.dart';
import '../repositories/auth_repository.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

class AuthState {
  final bool isAuthenticated;
  final UserInfo? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    UserInfo? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final Future<void> Function(UserInfo)? onAuthenticated;
  final Future<UserInfo?> Function()? restoreUser;
  final Future<void> Function()? onLoggedOut;

  AuthNotifier(
    this._repository, {
    this.onAuthenticated,
    this.restoreUser,
    this.onLoggedOut,
  }) : super(const AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final loggedIn = await _repository.isLoggedIn();
    if (loggedIn) {
      final user = await restoreUser?.call();
      state = state.copyWith(isAuthenticated: true, user: user);
      if (user != null) await _safeAuthenticated(user);
    }
  }

  Future<void> register(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.register(
        LoginRequest(email: email, password: password),
      );
      state = state.copyWith(
        isAuthenticated: true,
        user: response.user,
        isLoading: false,
        error: null,
      );
      await _safeAuthenticated(response.user);
    } catch (e) {
      final message = _extractError(e);
      state = state.copyWith(isLoading: false, error: message);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.login(
        LoginRequest(email: email, password: password),
      );
      state = state.copyWith(
        isAuthenticated: true,
        user: response.user,
        isLoading: false,
        error: null,
      );
      await _safeAuthenticated(response.user);
    } catch (e) {
      final message = _extractError(e);
      state = state.copyWith(isLoading: false, error: message);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    await onLoggedOut?.call();
    state = const AuthState();
  }

  Future<void> handleUnauthorized() {
    state = const AuthState();
    return Future.value();
  }

  Future<void> _safeAuthenticated(UserInfo user) async {
    try {
      await onAuthenticated?.call(user);
    } catch (_) {}
  }

  String _extractError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'] as String;
      }
      final detail = e.message;
      final suffix = (detail == null || detail.isEmpty) ? '' : '：$detail';
      return switch (e.type) {
        DioExceptionType.connectionTimeout => '连接服务器超时$suffix',
        DioExceptionType.sendTimeout => '发送请求超时$suffix',
        DioExceptionType.receiveTimeout => '服务器响应超时$suffix',
        DioExceptionType.badCertificate => '服务器证书校验失败$suffix',
        DioExceptionType.connectionError => '无法连接服务器$suffix',
        DioExceptionType.badResponse =>
          '服务器返回异常（HTTP ${e.response?.statusCode}）$suffix',
        DioExceptionType.transformTimeout => '处理响应超时$suffix',
        DioExceptionType.cancel => '请求已取消',
        DioExceptionType.unknown => '网络请求失败$suffix',
      };
    }
    return e.toString();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier(
    AuthRepository(),
    onAuthenticated: (user) async {
      try {
        await ref.read(syncServiceProvider).bootstrap(userId: user.id);
      } catch (_) {}
    },
    restoreUser: () async {
      final meta = await ref.read(offlineRepositoryProvider).getActiveSyncMeta();
      if (meta == null) return null;
      return UserInfo(id: meta.userId, email: meta.email ?? '');
    },
    onLoggedOut: () async {
      final meta = await ref.read(offlineRepositoryProvider).getActiveSyncMeta();
      if (meta != null) {
        await ref.read(offlineRepositoryProvider).clearUserData(meta.userId);
      }
    },
  );
  ApiClient.onUnauthorized = notifier.handleUnauthorized;
  return notifier;
});
