import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:karisreview/auth/models/auth_config.dart';
import 'package:karisreview/auth/providers/auth_provider.dart';
import 'package:karisreview/auth/repositories/auth_repository.dart';
import 'package:karisreview/card/providers/card_provider.dart';
import 'package:karisreview/card/repositories/card_repository.dart';
import 'package:karisreview/deck/providers/deck_provider.dart';
import 'package:karisreview/deck/repositories/deck_repository.dart';
import 'package:karisreview/review/providers/review_provider.dart';
import 'package:karisreview/review/repositories/review_repository.dart';
import 'package:karisreview/settings/providers/settings_provider.dart';
import 'package:karisreview/settings/repositories/settings_repository.dart';
import 'package:karisreview/shared/api/api_client.dart';
import 'package:karisreview/stats/models/stats.dart';
import 'package:karisreview/stats/providers/deck_stats_provider.dart';
import 'package:karisreview/stats/providers/stats_provider.dart';
import 'package:karisreview/stats/repositories/stats_repository.dart';
import 'package:mocktail/mocktail.dart';

String apiPath(String path) => 'http://localhost:8080/api$path';

Response<dynamic> okResponse(Object? data) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: '/'),
    statusCode: 200,
    data: {'code': 200, 'message': 'success', 'data': data},
  );
}

DioException apiError(String message, {int statusCode = 400}) {
  return DioException(
    requestOptions: RequestOptions(path: '/'),
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: RequestOptions(path: '/'),
      statusCode: statusCode,
      data: {'code': statusCode, 'message': message, 'data': null},
    ),
  );
}

DioException connectionError(String message) {
  return DioException(
    requestOptions: RequestOptions(path: '/'),
    type: DioExceptionType.connectionError,
    message: message,
  );
}

class FakeApiClient extends ApiClient {
  Future<Response> Function(String path, Map<String, dynamic>? query)? onGet;
  Future<Response> Function(String path, Object? data)? onPost;
  Future<Response> Function(String path, Object? data)? onPut;
  Future<Response> Function(String path)? onDelete;
  Future<List<int>> Function(String path, Map<String, dynamic>? query)? onGetProto;
  Future<List<int>> Function(String path, Map<String, dynamic>? query, List<int> body)? onPostProto;

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return onGet?.call(path, queryParameters) ?? Future.value(okResponse({}));
  }

  @override
  Future<Response> post(String path, {Object? data}) {
    return onPost?.call(path, data) ?? Future.value(okResponse({}));
  }

  @override
  Future<T> getProto<T extends pb.GeneratedMessage>(
      String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(List<int>) parse,
  }) async {
    final handler = onGetProto;
    if (handler == null) throw UnimplementedError('未配置 getProto');
    final bytes = await handler(path, queryParameters);
    return parse(bytes);
  }

  @override
  Future<T> postProto<T extends pb.GeneratedMessage>(
    String path, {
    required List<int> data,
    required T Function(List<int>) parse,
  }) async {
    final handler = onPostProto;
    if (handler == null) throw UnimplementedError('未配置 postProto');
    final bytes = await handler(path, null, data);
    return parse(bytes);
  }

  @override
  Future<Response> put(String path, {Object? data}) {
    return onPut?.call(path, data) ?? Future.value(okResponse({}));
  }

  @override
  Future<Response> delete(String path) {
    return onDelete?.call(path) ?? Future.value(okResponse({}));
  }
}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockDeckRepository extends Mock implements DeckRepository {}

class MockCardRepository extends Mock implements CardRepository {}

class MockReviewRepository extends Mock implements ReviewRepository {}

class MockStatsRepository extends Mock implements StatsRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class FakeReviewNotifier extends ReviewNotifier {
  FakeReviewNotifier(super.repository, ReviewSessionState initial) {
    state = initial;
  }
}

Map<String, dynamic> deckJson({
  String id = 'deck-1',
  String name = '日语 N5',
  int cardCount = 2,
  int dueCount = 1,
}) {
  return {
    'id': id,
    'name': name,
    'card_count': cardCount,
    'due_count': dueCount,
    'new_count': 1,
    'mastered_count': 0,
    'stage_distribution': [1, 1, 0, 0, 0, 0, 0, 0, 0],
    'due_stage_distribution': [1, 0, 0, 0, 0, 0, 0, 0, 0],
    'created_at': '2025-08-01T10:00:00Z',
  };
}

Map<String, dynamic> cardJson({
  String id = 'card-1',
  String deckId = 'deck-1',
  String front = '正面',
  String back = '反面',
  int stage = 0,
  bool learning = false,
  String? nextReviewDate,
  int consecutiveFamiliar = 0,
  int? learningGoal,
}) {
  return {
    'id': id,
    'deck_id': deckId,
    'front': front,
    'back': back,
    'stage': stage,
    'next_review_date': nextReviewDate,
    'learning_mode': learning,
    'consecutive_familiar': consecutiveFamiliar,
    'learning_step': 0,
    'reentry_stage': null,
    'learning_goal': learningGoal,
    'due': false,
    'created_at': '2025-08-01T10:00:00Z',
  };
}

Map<String, dynamic> reviewCardJson({
  String id = 'card-1',
  String deckId = 'deck-1',
  String front = '正面',
}) {
  return {
    'id': id,
    'deck_id': deckId,
    'front': front,
    'back': '反面',
    'stage': 0,
    'learning_mode': false,
    'consecutive_familiar': 0,
    'reentry_stage': null,
    'next_review_date': null,
    'review_version': 0,
  };
}

Map<String, dynamic> reviewResultJson({
  String cardId = 'card-1',
  String rating = 'FAMILIAR',
}) {
  return {
    'card_id': cardId,
    'rating': rating,
    'stage_before': 0,
    'stage_after': 1,
    'next_review_date': '2025-08-02',
    'learning_mode': false,
    'consecutive_familiar': 0,
    'next_interval_days': 1,
  };
}

Map<String, dynamic> overviewStatsJson({
  int dueToday = 3,
  int newCards = 1,
}) {
  return {
    'total_cards': 10,
    'total_decks': 2,
    'due_today': dueToday,
    'reviewed_today': 4,
    'learned_today': 1,
    'mastered_cards': 2,
    'new_cards': newCards,
    'learning_cards': 8,
    'stage_distribution': [8, 0, 0, 0, 0, 2, 0, 0, 0],
    'due_stage_distribution': [3, 0, 0, 0, 0, 0, 0, 0, 0],
  };
}

Map<String, dynamic> deckStatsJson() {
  return {
    'deck_id': 'deck-1',
    'deck_name': '日语 N5',
    'total_cards': 2,
    'due_today': 1,
    'reviewed_today': 1,
    'new_cards': 1,
    'learning_cards': 0,
    'mastered_cards': 0,
    'stage_distribution': [2, 0, 0, 0, 0, 0, 0, 0, 0],
    'due_stage_distribution': [1, 0, 0, 0, 0, 0, 0, 0, 0],
  };
}

Map<String, dynamic> trendPointJson() {
  return {'date': '2025-08-01', 'reviewed': 3, 'learned': 1};
}

Map<String, dynamic> importPreviewJson() {
  return {
    'total': 2,
    'valid_count': 1,
    'invalid_count': 1,
    'cards': [
      {'index': 0, 'front': '正面', 'back': '反面', 'valid': true, 'message': null},
      {
        'index': 1,
        'front': '',
        'back': '反面',
        'valid': false,
        'message': '正面内容不能为空',
      },
    ],
  };
}

Map<String, dynamic> validImportPreviewJson() {
  return {
    'total': 2,
    'valid_count': 2,
    'invalid_count': 0,
    'cards': [
      {'index': 0, 'front': '正面', 'back': '反面', 'valid': true, 'message': null},
      {
        'index': 1,
        'front': '第二张',
        'back': '反面二',
        'valid': true,
        'message': null,
      },
    ],
  };
}

Map<String, dynamic> importResultJson({
  int importedCards = 2,
  List<String> importedCardIds = const ['card-1', 'card-2'],
}) {
  return {
    'imported_cards': importedCards,
    'imported_card_ids': importedCardIds,
  };
}

DeckStats deckStats() => DeckStats.fromJson(deckStatsJson());

TrendPoint trendPoint() => TrendPoint.fromJson(trendPointJson());
List<Override> authOverrides(
  MockAuthRepository repo, {
  bool inviteCodeRequired = false,
}) => [
  authProvider.overrideWith((ref) => AuthNotifier(repo)),
  authConfigProvider.overrideWith(
    (ref) async => AuthConfig(inviteCodeRequired: inviteCodeRequired),
  ),
];

List<Override> reviewOverrides(
  MockReviewRepository repo,
  ReviewSessionState state,
) => [reviewProvider.overrideWith((ref) => FakeReviewNotifier(repo, state))];

List<Override> deckOverrides(MockDeckRepository repo) => [
  deckListProvider.overrideWith((ref) => DeckListNotifier(repo)),
];

List<Override> cardOverrides(MockCardRepository repo) => [
  cardListProvider.overrideWith((ref, args) => CardListNotifier(repo, args)),
];

List<Override> statsOverrides(MockStatsRepository repo) => [
  statsProvider.overrideWith((ref) => StatsNotifier(repo)),
  deckStatsProvider.overrideWith((ref, deckId) async => deckStats()),
  trendProvider.overrideWith((ref, days) async => [trendPoint()]),
];

List<Override> settingsOverrides(MockSettingsRepository repo) => [
  settingsProvider.overrideWith((ref) => SettingsNotifier(repo)),
];
