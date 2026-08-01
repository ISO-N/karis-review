import '../../shared/api/api_client.dart';
import '../../shared/api/api_endpoints.dart';
import '../models/deck.dart';

class DeckRepository {
  final ApiClient _client = ApiClient();

  Future<List<Deck>> getDecks() async {
    final response = await _client.get(ApiEndpoints.decks);
    final data = response.data['data'] as List<dynamic>;
    return data.map((d) => Deck.fromJson(d as Map<String, dynamic>)).toList();
  }

  Future<Deck> createDeck(String name) async {
    final response = await _client.post(ApiEndpoints.decks, data: {'name': name});
    final data = response.data['data'] as Map<String, dynamic>;
    return Deck.fromJson(data);
  }

  Future<Deck> updateDeck(String id, String name) async {
    final response = await _client.put(ApiEndpoints.deck(id), data: {'name': name});
    final data = response.data['data'] as Map<String, dynamic>;
    return Deck.fromJson(data);
  }

  Future<void> deleteDeck(String id) async {
    await _client.delete(ApiEndpoints.deck(id));
  }
}