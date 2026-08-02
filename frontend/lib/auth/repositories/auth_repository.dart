import '../../shared/api/api_client.dart';
import '../../shared/api/api_endpoints.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

class AuthRepository {
  final ApiClient _client;

  AuthRepository({ApiClient? client}) : _client = client ?? ApiClient.shared;

  Future<LoginResponse> register(LoginRequest request) async {
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
}
