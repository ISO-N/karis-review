import '../../shared/api/api_client.dart';
import '../../shared/api/api_endpoints.dart';
import '../models/stats.dart';

class StatsRepository {
  final ApiClient _client = ApiClient();

  Future<OverviewStats> getOverview() async {
    final response = await _client.get(ApiEndpoints.statsOverview);
    final data = response.data['data'] as Map<String, dynamic>;
    return OverviewStats.fromJson(data);
  }

  Future<DeckStats> getDeckStats(String deckId) async {
    final response = await _client.get(ApiEndpoints.statsDeck(deckId));
    final data = response.data['data'] as Map<String, dynamic>;
    return DeckStats.fromJson(data);
  }

  Future<List<TrendPoint>> getTrend({int days = 30}) async {
    final response = await _client.get(
      ApiEndpoints.statsTrend,
      queryParameters: {'days': days},
    );
    final data = response.data['data'] as List<dynamic>;
    return data.map((d) => TrendPoint.fromJson(d as Map<String, dynamic>)).toList();
  }
}