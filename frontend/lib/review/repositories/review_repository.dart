import 'package:dio/dio.dart';

import '../../shared/api/api_client.dart';
import '../../shared/api/api_endpoints.dart';
import '../../shared/proto/karis_review.pb.dart' as proto;
import '../../shared/proto/proto_mappers.dart';
import '../models/review_card.dart';

class ReviewRepository {
  final ApiClient _client;

  ReviewRepository({ApiClient? client}) : _client = client ?? ApiClient.shared;

  Future<List<ReviewCard>> getDueCards({String? deckId, int limit = 500}) async {
    final params = <String, dynamic>{'limit': limit};
    if (deckId != null) params['deck_id'] = deckId;
    try {
      final protoMessage = await _client.getProto<proto.ReviewCardListResponse>(
        ApiEndpoints.reviewDue,
        queryParameters: params,
        parse: proto.ReviewCardListResponse.fromBuffer,
      );
      return reviewCardListToMaps(protoMessage)
          .map(ReviewCard.fromJson)
          .toList();
    } on DioException catch (e) {
      if (_unsupported(e)) {
        final response = await _client.get(
          ApiEndpoints.reviewDue,
          queryParameters: params,
        );
        final data = response.data['data'] as List<dynamic>;
        return data
            .map((c) => ReviewCard.fromJson(c as Map<String, dynamic>))
            .toList();
      }
      rethrow;
    }
  }

  Future<List<ReviewCard>> getNewCards({String? deckId, int limit = 10}) async {
    final params = <String, dynamic>{'limit': limit};
    if (deckId != null) params['deck_id'] = deckId;
    try {
      final protoMessage = await _client.getProto<proto.ReviewCardListResponse>(
        ApiEndpoints.reviewNew,
        queryParameters: params,
        parse: proto.ReviewCardListResponse.fromBuffer,
      );
      return reviewCardListToMaps(protoMessage)
          .map(ReviewCard.fromJson)
          .toList();
    } on DioException catch (e) {
      if (_unsupported(e)) {
        final response = await _client.get(
          ApiEndpoints.reviewNew,
          queryParameters: params,
        );
        final data = response.data['data'] as List<dynamic>;
        return data
            .map((c) => ReviewCard.fromJson(c as Map<String, dynamic>))
            .toList();
      }
      rethrow;
    }
  }

  Future<ReviewResult> rateCard(String cardId, String rating) async {
    final response = await _client.post(
      ApiEndpoints.rateCard(cardId),
      data: {'rating': rating},
    );
    return ReviewResult.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  bool _unsupported(DioException e) {
    return e.response?.statusCode == 401 ||
        e.response?.statusCode == 406 ||
        e.response?.statusCode == 415;
  }
}
