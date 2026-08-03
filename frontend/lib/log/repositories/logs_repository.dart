import '../../shared/api/api_client.dart';
import '../../shared/api/api_endpoints.dart';

class LogsRepository {
  final ApiClient _client;

  LogsRepository({ApiClient? client}) : _client = client ?? ApiClient.shared;

  Future<Map<String, dynamic>> getLogs({
    int page = 0,
    int size = 50,
    String? level,
    String? category,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (level != null && level.isNotEmpty) {
      queryParams['level'] = level;
    }
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    final uri = Uri.parse('${ApiEndpoints.logs}?${Uri(queryParameters: queryParams).query}');
    final response = await _client.get(uri.toString());
    return response.data['data'] as Map<String, dynamic>;
  }
}