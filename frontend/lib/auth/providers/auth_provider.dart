import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  AuthNotifier(this._repository) : super(const AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final loggedIn = await _repository.isLoggedIn();
    if (loggedIn) {
      state = state.copyWith(isAuthenticated: true);
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
    } catch (e) {
      final message = _extractError(e);
      state = state.copyWith(isLoading: false, error: message);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState();
  }

  String _extractError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'] as String;
      }
      return '网络请求失败';
    }
    return e.toString();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(AuthRepository());
});