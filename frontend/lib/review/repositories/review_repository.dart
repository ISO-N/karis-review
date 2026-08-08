import '../../shared/api/api_client.dart';
import '../../shared/api/api_endpoints.dart';
import '../../shared/proto/karis_review.pb.dart' as proto;
import '../../shared/proto/proto_mappers.dart';
import '../models/review_card.dart';

class ReviewRepository {
  final ApiClient _client;

  ReviewRepository({ApiClient? client}) : _client = client ?? ApiClient.shared;

  // 内容协商统一走 ApiClient.getData（架构评审 F3）：
  // proto 优先，服务端不支持（401/406/415）时自动回退 JSON。

  Future<List<ReviewCard>> getDueCards({String? deckId, int limit = 500}) async {
    final params = <String, dynamic>{'limit': limit};
    if (deckId != null) params['deck_id'] = deckId;
    final data = await _client.getData<proto.ReviewCardListResponse>(
      ApiEndpoints.reviewDue,
      queryParameters: params,
      parse: proto.ReviewCardListResponse.fromBuffer,
      toData: reviewCardListToMaps,
    );
    return (data as List<dynamic>)
        .map((c) => ReviewCard.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<List<ReviewCard>> getNewCards({String? deckId, int limit = 10}) async {
    final params = <String, dynamic>{'limit': limit};
    if (deckId != null) params['deck_id'] = deckId;
    final data = await _client.getData<proto.ReviewCardListResponse>(
      ApiEndpoints.reviewNew,
      queryParameters: params,
      parse: proto.ReviewCardListResponse.fromBuffer,
      toData: reviewCardListToMaps,
    );
    return (data as List<dynamic>)
        .map((c) => ReviewCard.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<ReviewResult> rateCard(String cardId, String rating) async {
    final response = await _client.post(
      ApiEndpoints.rateCard(cardId),
      data: {'rating': rating},
    );
    return ReviewResult.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
