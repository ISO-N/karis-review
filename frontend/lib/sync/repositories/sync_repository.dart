import 'package:dio/dio.dart';
import 'package:fixnum/fixnum.dart';

import '../../shared/api/api_client.dart';
import '../../shared/api/api_endpoints.dart';
import '../../shared/proto/karis_review.pb.dart' as proto;
import '../../shared/proto/proto_mappers.dart';

class SyncRepository {
  final ApiClient _client;

  SyncRepository({ApiClient? client}) : _client = client ?? ApiClient.shared;

  Future<Map<String, dynamic>> fetchBootstrap({int eventCursor = 0}) async {
    try {
      final message = await _client.getProto<proto.SyncResponse>(
        ApiEndpoints.syncBootstrap,
        queryParameters: {'event_cursor': eventCursor},
        parse: proto.SyncResponse.fromBuffer,
      );
      return syncResponseToMap(message);
    } on DioException catch (e) {
      if (isProtoUnsupported(e)) {
        final response = await _client.get(
          ApiEndpoints.syncBootstrap,
          queryParameters: {'event_cursor': eventCursor},
        );
        return response.data['data'] as Map<String, dynamic>;
      }
      rethrow;
    }
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
    try {
      final message = await _client.postProto<proto.ReviewSessionPageResponse>(
        ApiEndpoints.reviewSessions,
        data: request.writeToBuffer(),
        parse: proto.ReviewSessionPageResponse.fromBuffer,
      );
      return reviewSessionPageToMap(message);
    } on DioException catch (e) {
      if (isProtoUnsupported(e)) {
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
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchReviewSessionPage({
    required String sessionId,
    required int cursor,
    int limit = 10,
  }) async {
    try {
      final message = await _client.getProto<proto.ReviewSessionPageResponse>(
        ApiEndpoints.reviewSession(sessionId),
        queryParameters: {'cursor': cursor, 'limit': limit},
        parse: proto.ReviewSessionPageResponse.fromBuffer,
      );
      return reviewSessionPageToMap(message);
    } on DioException catch (e) {
      if (isProtoUnsupported(e)) {
        final response = await _client.get(
          ApiEndpoints.reviewSession(sessionId),
          queryParameters: {'cursor': cursor, 'limit': limit},
        );
        return response.data['data'] as Map<String, dynamic>;
      }
      rethrow;
    }
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
    try {
      final message = await _client.postProto<proto.ReviewSyncResponse>(
        ApiEndpoints.reviewSync,
        data: request.writeToBuffer(),
        parse: proto.ReviewSyncResponse.fromBuffer,
      );
      return reviewSyncResponseToMap(message);
    } on DioException catch (e) {
      if (isProtoUnsupported(e)) {
        final response = await _client.post(
          ApiEndpoints.reviewSync,
          data: {'items': items},
        );
        return response.data['data'] as Map<String, dynamic>;
      }
      rethrow;
    }
  }
}
