import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../offline/providers.dart';
import '../../shared/api/api_client.dart';
import '../../shared/providers/data_refresh_provider.dart';
import '../../sync/providers.dart';
import '../models/auth_config.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/register_request.dart';
import '../repositories/auth_repository.dart';

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

  Future<void> register(
    String email,
    String password, {
    String? inviteCode,
    required String verificationCode,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.register(
        RegisterRequest(
          email: email,
          password: password,
          inviteCode: inviteCode,
          verificationCode: verificationCode,
        ),
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

  /// 修改密码：成功后主动登出（服务端不强制吊销已有 Token）。
  Future<void> changePassword(String currentPassword, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.changePassword(currentPassword, newPassword);
      await logout();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  /// 发送找回密码验证码（邮箱不存在也按成功返回，防枚举）。
  Future<void> sendResetCode(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.sendResetCode(email);
      state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  /// 发送注册邮箱验证码（邮箱已注册时后端返回错误）。
  Future<void> sendRegisterCode(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.sendRegisterCode(email);
      state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  /// 用验证码重置密码（未登录场景，成功后由页面跳转登录页）。
  Future<void> resetPassword(String email, String code, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.resetPassword(email, code, newPassword);
      state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
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
        final offline = ref.read(offlineRepositoryProvider);
        final meta = await offline.getActiveSyncMeta();
        final sync = ref.read(syncServiceProvider);
        if (meta == null || meta.userId != user.id) {
          await sync.bootstrap(userId: user.id);
        } else {
          await sync.refresh();
        }
        await ref.read(dataRefreshControllerProvider).armDailyRefresh();
      } catch (_) {}
    },
    restoreUser: () async {
      final offline = ref.read(offlineRepositoryProvider);
      final meta = await offline.getActiveSyncMeta();
      if (meta != null) {
        return UserInfo(id: meta.userId, email: meta.email ?? '');
      }
      try {
        return await ref.read(syncServiceProvider).bootstrapFromServer();
      } catch (_) {
        return null;
      }
    },
    onLoggedOut: () async {
      final meta = await ref
          .read(offlineRepositoryProvider)
          .getActiveSyncMeta();
      if (meta != null) {
        await ref.read(offlineRepositoryProvider).clearUserData(meta.userId);
      }
      ref.read(dataRefreshControllerProvider).cancelDailyRefresh();
    },
  );
  ApiClient.onUnauthorized = notifier.handleUnauthorized;
  return notifier;
});

final authConfigProvider = FutureProvider<AuthConfig>((ref) {
  return AuthRepository().getAuthConfig();
});
