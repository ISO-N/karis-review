import '../../shared/api/api_client.dart';
import '../../shared/api/api_endpoints.dart';

class SyncRepository {
  final ApiClient _client;

  SyncRepository({ApiClient? client}) : _client = client ?? ApiClient.shared;

  Future<Map<String, dynamic>> fetchBootstrap() async {
    final response = await _client.get(ApiEndpoints.syncBootstrap);
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createReviewSession({
    required String mode,
    String? deckId,
    int batchSize = 10,
  }) async {
    final response = await _client.post(
      ApiEndpoints.reviewSessions,
      data: {
        'mode': mode,
        'deck_id': deckId,
        'batch_size': batchSize,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchReviewSessionPage({
    required String sessionId,
    required int cursor,
    int limit = 10,
  }) async {
    final response = await _client.get(
      ApiEndpoints.reviewSession(sessionId),
      queryParameters: {'cursor': cursor, 'limit': limit},
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<void> deleteReviewSession(String sessionId) async {
    await _client.delete(ApiEndpoints.reviewSession(sessionId));
  }

  Future<Map<String, dynamic>> syncRatings(
    List<Map<String, dynamic>> items,
  ) async {
    final response = await _client.post(
      ApiEndpoints.reviewSync,
      data: {'items': items},
    );
    return response.data['data'] as Map<String, dynamic>;
  }
}
