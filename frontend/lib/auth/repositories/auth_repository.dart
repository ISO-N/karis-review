import '../../shared/api/api_client.dart';
import '../../shared/api/api_endpoints.dart';
import '../models/auth_config.dart';
import '../models/change_password_request.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/register_request.dart';

class AuthRepository {
  final ApiClient _client;

  AuthRepository({ApiClient? client}) : _client = client ?? ApiClient.shared;

  Future<AuthConfig> getAuthConfig() async {
    final response = await _client.get(ApiEndpoints.authConfig);
    final data = response.data['data'] as Map<String, dynamic>;
    return AuthConfig.fromJson(data);
  }

  Future<LoginResponse> register(RegisterRequest request) async {
    final response = await _client.post(
      ApiEndpoints.register,
      data: request.toJson(),
    );
    final data = response.data['data'] as Map<String, dynamic>;
    final loginResponse = LoginResponse.fromJson(data);
    await ApiClient.saveToken(loginResponse.token);
    return loginResponse;
  }

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _client.post(
      ApiEndpoints.login,
      data: request.toJson(),
    );
    final data = response.data['data'] as Map<String, dynamic>;
    final loginResponse = LoginResponse.fromJson(data);
    await ApiClient.saveToken(loginResponse.token);
    return loginResponse;
  }

  Future<void> logout() async {
    try {
      await _client.post(ApiEndpoints.logout);
    } catch (_) {}
    await ApiClient.clearToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await ApiClient.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _client.put(
      ApiEndpoints.changePassword,
      data: ChangePasswordRequest(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ).toJson(),
    );
  }

  Future<void> sendResetCode(String email) async {
    await _client.post(
      ApiEndpoints.authPasswordResetCode,
      data: {'email': email},
    );
  }

  Future<void> sendRegisterCode(String email) async {
    await _client.post(
      ApiEndpoints.authRegisterCode,
      data: {'email': email},
    );
  }

  Future<void> resetPassword(String email, String code, String newPassword) async {
    await _client.post(
      ApiEndpoints.authPasswordReset,
      data: {
        'email': email,
        'code': code,
        'new_password': newPassword,
      },
    );
  }
}
