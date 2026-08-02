import '../../shared/api/api_client.dart';
import '../../shared/api/api_endpoints.dart';
import '../models/review_card.dart';

class ReviewRepository {
  final ApiClient _client;

  ReviewRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<ReviewCard>> getDueCards({String? deckId}) async {
    final params = <String, dynamic>{};
    if (deckId != null) params['deck_id'] = deckId;
    final response = await _client.get(
      ApiEndpoints.reviewDue,
      queryParameters: params,
    );
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((c) => ReviewCard.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<List<ReviewCard>> getNewCards({String? deckId}) async {
    final params = <String, dynamic>{};
    if (deckId != null) params['deck_id'] = deckId;
    final response = await _client.get(
      ApiEndpoints.reviewNew,
      queryParameters: params,
    );
    final data = response.data['data'] as List<dynamic>;
    return data
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
