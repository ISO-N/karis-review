import '../../shared/api/api_client.dart';
import '../../shared/api/api_endpoints.dart';
import '../models/card.dart';

class CardRepository {
  final ApiClient _client;

  CardRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> getDeckCards(
    String deckId, {
    int page = 0,
    int size = 500,
    String filter = 'all',
  }) async {
    final response = await _client.get(
      ApiEndpoints.deckCards(deckId),
      queryParameters: {'page': page, 'size': size, 'filter': filter},
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<FlashCard> getCard(String cardId) async {
    final response = await _client.get(ApiEndpoints.card(cardId));
    final data = response.data['data'] as Map<String, dynamic>;
    return FlashCard.fromJson(data);
  }

  Future<FlashCard> createCard(String deckId, String front, String back) async {
    final response = await _client.post(
      ApiEndpoints.deckCards(deckId),
      data: {'front': front, 'back': back},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return FlashCard.fromJson(data);
  }

  Future<FlashCard> updateCard(String cardId, String front, String back) async {
    final response = await _client.put(
      ApiEndpoints.card(cardId),
      data: {'front': front, 'back': back},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return FlashCard.fromJson(data);
  }

  Future<Map<String, dynamic>> previewCardImport(
    String deckId,
    String content,
  ) async {
    final response = await _client.post(
      ApiEndpoints.cardImportPreview(deckId),
      data: {'content': content},
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> importCards(
    String deckId,
    List<Map<String, dynamic>> cards,
  ) async {
    final response = await _client.post(
      ApiEndpoints.cardImport(deckId),
      data: {'cards': cards},
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<void> deleteCard(String cardId) async {
    await _client.delete(ApiEndpoints.card(cardId));
  }
}
