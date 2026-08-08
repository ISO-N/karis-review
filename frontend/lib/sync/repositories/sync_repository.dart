import 'package:fixnum/fixnum.dart';

import '../../shared/api/api_client.dart';
import '../../shared/api/api_endpoints.dart';
import '../../shared/proto/karis_review.pb.dart' as proto;
import '../../shared/proto/proto_mappers.dart';

class SyncRepository {
  final ApiClient _client;

  SyncRepository({ApiClient? client}) : _client = client ?? ApiClient.shared;

  // 内容协商统一走 ApiClient.getData/postData（架构评审 F3）：
  // proto 优先，服务端不支持（401/406/415）时自动回退 JSON。

  Future<Map<String, dynamic>> fetchBootstrap({int eventCursor = 0}) async {
    final data = await _client.getData<proto.SyncResponse>(
      ApiEndpoints.syncBootstrap,
      queryParameters: {'event_cursor': eventCursor},
      parse: proto.SyncResponse.fromBuffer,
      toData: syncResponseToMap,
    );
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createReviewSession({
    required String mode,
    String? deckId,
    int batchSize = 10,
  }) async {
    final request = proto.ReviewSessionCreateRequest(
      mode: mode,
      deckId: deckId,
      batchSize: batchSize,
    );
    final data = await _client.postData<proto.ReviewSessionPageResponse>(
      ApiEndpoints.reviewSessions,
      protoData: request.writeToBuffer(),
      parse: proto.ReviewSessionPageResponse.fromBuffer,
      toData: reviewSessionPageToMap,
      jsonData: {
        'mode': mode,
        'deck_id': deckId,
        'batch_size': batchSize,
      },
    );
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchReviewSessionPage({
    required String sessionId,
    required int cursor,
    int limit = 10,
  }) async {
    final data = await _client.getData<proto.ReviewSessionPageResponse>(
      ApiEndpoints.reviewSession(sessionId),
      queryParameters: {'cursor': cursor, 'limit': limit},
      parse: proto.ReviewSessionPageResponse.fromBuffer,
      toData: reviewSessionPageToMap,
    );
    return data as Map<String, dynamic>;
  }

  Future<void> deleteReviewSession(String sessionId) async {
    await _client.delete(ApiEndpoints.reviewSession(sessionId));
  }

  Future<Map<String, dynamic>> syncRatings(
    List<Map<String, dynamic>> items,
  ) async {
    final protoItems = items.map((item) {
      return proto.ReviewSyncItem(
        clientRequestId: item['client_request_id'] as String,
        cardId: item['card_id'] as String,
        rating: item['rating'] as String,
        ratedAt: item['rated_at'] as String,
        reviewVersion: Int64((item['review_version'] as num).toInt()),
      );
    }).toList();
    final request = proto.ReviewSyncRequest(items: protoItems);
    final data = await _client.postData<proto.ReviewSyncResponse>(
      ApiEndpoints.reviewSync,
      protoData: request.writeToBuffer(),
      parse: proto.ReviewSyncResponse.fromBuffer,
      toData: reviewSyncResponseToMap,
      jsonData: {'items': items},
    );
    return data as Map<String, dynamic>;
  }
}
