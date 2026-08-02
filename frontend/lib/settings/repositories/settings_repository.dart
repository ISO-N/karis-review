import '../../shared/api/api_client.dart';
import '../../shared/api/api_endpoints.dart';

class SettingsRepository {
  final ApiClient _client;

  SettingsRepository({ApiClient? client}) : _client = client ?? ApiClient.shared;

  Future<Map<String, dynamic>> getSettings() async {
    final response = await _client.get(ApiEndpoints.settings);
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateSettings(String refreshTime) async {
    final response = await _client.put(
      ApiEndpoints.settings,
      data: {'refresh_time': refreshTime},
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> exportBackup() async {
    final response = await _client.post(ApiEndpoints.backupExport);
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> importBackup(Map<String, dynamic> data) async {
    final response = await _client.post(
      ApiEndpoints.backupImport,
      data: {'data': data},
    );
    return response.data['data'] as Map<String, dynamic>;
  }
}
