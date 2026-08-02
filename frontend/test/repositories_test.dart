import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karisreview/auth/models/login_request.dart';
import 'package:karisreview/auth/repositories/auth_repository.dart';
import 'package:karisreview/card/repositories/card_repository.dart';
import 'package:karisreview/deck/repositories/deck_repository.dart';
import 'package:karisreview/review/repositories/review_repository.dart';
import 'package:karisreview/settings/repositories/settings_repository.dart';
import 'package:karisreview/shared/api/api_client.dart';
import 'package:karisreview/shared/proto/karis_review.pb.dart' as proto;
import 'package:karisreview/stats/repositories/stats_repository.dart';
import 'package:karisreview/sync/repositories/sync_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthRepository', () {
    test('registers, saves token, and parses user', () async {
      final client = FakeApiClient();
      client.onPost = (path, data) async {
        expect(path, apiPath('/auth/register'));
        expect(data, {'email': 'a@b.c', 'password': 'secret'});
        return okResponse({
          'token': 'token-1',
          'user': {'id': 'u1', 'email': 'a@b.c'},
        });
      };
      final repository = AuthRepository(client: client);

      final response = await repository.register(
        LoginRequest(email: 'a@b.c', password: 'secret'),
      );

      expect(response.token, 'token-1');
      expect(response.user.email, 'a@b.c');
      expect(await ApiClient.getToken(), 'token-1');
    });
  });

  group('DeckRepository', () {
    test('gets decks and parses list', () async {
      final client = FakeApiClient();
      client.onGet = (path, query) async {
        expect(path, apiPath('/decks'));
        return okResponse([deckJson()]);
      };
      final repository = DeckRepository(client: client);

      final decks = await repository.getDecks();

      expect(decks.single.name, '日语 N5');
      expect(decks.single.cardCount, 2);
    });

    test('creates, updates, and deletes with expected payloads', () async {
      final client = FakeApiClient();
      client.onPost = (path, data) async {
        expect(path, apiPath('/decks'));
        expect(data, {'name': '新牌组'});
        return okResponse(deckJson(name: '新牌组'));
      };
      final repository = DeckRepository(client: client);

      final created = await repository.createDeck('新牌组');
      expect(created.name, '新牌组');

      client.onPut = (path, data) async {
        expect(path, apiPath('/decks/deck-1'));
        expect(data, {'name': '改名'});
        return okResponse(deckJson(name: '改名'));
      };
      expect((await repository.updateDeck('deck-1', '改名')).name, '改名');

      client.onDelete = (path) async {
        expect(path, apiPath('/decks/deck-1'));
        return okResponse(null);
      };
      await repository.deleteDeck('deck-1');
    });
  });

  group('CardRepository', () {
    test('lists cards with query parameters', () async {
      final client = FakeApiClient();
      client.onGet = (path, query) async {
        expect(path, apiPath('/decks/deck-1/cards'));
        expect(query, {'page': 0, 'size': 500, 'filter': 'all'});
        return okResponse({
          'content': [cardJson()],
          'page': 0,
          'size': 20,
          'total_elements': 1,
          'total_pages': 1,
        });
      };
      final repository = CardRepository(client: client);

      final data = await repository.getDeckCards('deck-1');

      expect((data['content'] as List).length, 1);
    });

    test('creates and updates cards', () async {
      final client = FakeApiClient();
      client.onPost = (path, data) async {
        expect(path, apiPath('/decks/deck-1/cards'));
        expect(data, {'front': 'f', 'back': 'b'});
        return okResponse(cardJson());
      };
      final repository = CardRepository(client: client);
      expect((await repository.createCard('deck-1', 'f', 'b')).front, '正面');

      client.onPut = (path, data) async {
        expect(path, apiPath('/cards/card-1'));
        expect(data, {'front': 'f2', 'back': 'b2'});
        return okResponse(cardJson(front: 'f2'));
      };
      expect((await repository.updateCard('card-1', 'f2', 'b2')).front, 'f2');
    });

    test('previews and imports card JSON', () async {
      final client = FakeApiClient();
      client.onPost = (path, data) async {
        if (path.endsWith('/preview')) {
          expect(data, {'content': '[{}]'});
          return okResponse(importPreviewJson());
        }
        expect(path, apiPath('/decks/deck-1/cards/import'));
        expect(data, {'cards': <Map<String, dynamic>>[]});
        return okResponse({'imported_cards': 2});
      };
      final repository = CardRepository(client: client);

      final preview = await repository.previewCardImport('deck-1', '[{}]');
      expect(preview['valid_count'], 1);

      final imported = await repository.importCards('deck-1', []);
      expect(imported['imported_cards'], 2);
    });
  });

  group('ReviewRepository', () {
    test('gets due and new queues', () async {
      final client = FakeApiClient();
      client.onGetProto = (path, query) async {
        expect(path, apiPath('/review/due'));
        expect(query, {'limit': 500, 'deck_id': 'deck-1'});
        return proto.ReviewCardListResponse(cards: [
          proto.ReviewCard(
            id: 'card-1',
            deckId: 'deck-1',
            front: '正面',
            back: '反面',
          ),
        ]).writeToBuffer();
      };
      final repository = ReviewRepository(client: client);

      final due = await repository.getDueCards(deckId: 'deck-1');
      expect(due.single.id, 'card-1');

      client.onGetProto = (path, query) async {
        expect(path, apiPath('/review/new'));
        expect(query, {'limit': 10, 'deck_id': 'deck-1'});
        return proto.ReviewCardListResponse(cards: [
          proto.ReviewCard(
            id: 'card-2',
            deckId: 'deck-1',
            front: '正面',
            back: '反面',
          ),
        ]).writeToBuffer();
      };
      final news = await repository.getNewCards(deckId: 'deck-1');
      expect(news.single.front, '正面');
    });

    test('rates card', () async {
      final client = FakeApiClient();
      client.onPost = (path, data) async {
        expect(path, apiPath('/review/card-1/rate'));
        expect(data, {'rating': 'FAMILIAR'});
        return okResponse(reviewResultJson());
      };
      final repository = ReviewRepository(client: client);

      final result = await repository.rateCard('card-1', 'FAMILIAR');

      expect(result.stageAfter, 1);
    });
  });

  group('SyncRepository', () {
    test('protobuf 401 falls back to JSON without losing token', () async {
      final client = FakeApiClient();
      client.onGetProto = (path, query) async {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: path),
            statusCode: 401,
          ),
        );
      };
      client.onGet = (path, query) async {
        expect(path, apiPath('/sync/bootstrap'));
        expect(query, {'event_cursor': 0});
        return okResponse({
          'server_time': '2026-01-01T00:00:00Z',
          'user': {'id': 'u1', 'email': 'a@b.c', 'refresh_time': '04:00:00'},
          'decks': [],
          'review_logs': [],
          'event_cursor': 0,
          'has_more': false,
          'reset_required': false,
        });
      };

      final data = await SyncRepository(client: client).fetchBootstrap();
      expect(data['user']['email'], 'a@b.c');
    });
  });

  group('StatsRepository', () {
    test('gets overview, deck stats, and trend', () async {
      final client = FakeApiClient();
      client.onGet = (path, query) async {
        if (path == apiPath('/stats/overview')) {
          return okResponse(overviewStatsJson());
        }
        if (path == apiPath('/stats/deck/deck-1')) {
          return okResponse(deckStatsJson());
        }
        expect(path, apiPath('/stats/trend'));
        expect(query, {'days': 7});
        return okResponse([trendPointJson()]);
      };
      final repository = StatsRepository(client: client);

      expect((await repository.getOverview()).totalCards, 10);
      expect((await repository.getDeckStats('deck-1')).deckName, '日语 N5');
      expect((await repository.getTrend(days: 7)).single.reviewed, 3);
    });
  });

  group('SettingsRepository', () {
    test('gets and updates settings', () async {
      final client = FakeApiClient();
      client.onGet = (path, query) async {
        expect(path, apiPath('/settings'));
        return okResponse({'email': 'a@b.c', 'refresh_time': '04:00:00'});
      };
      final repository = SettingsRepository(client: client);

      final settings = await repository.getSettings();
      expect(settings['refresh_time'], '04:00:00');

      client.onPut = (path, data) async {
        expect(path, apiPath('/settings'));
        expect(data, {'refresh_time': '03:00:00'});
        return okResponse({'email': 'a@b.c', 'refresh_time': '03:00:00'});
      };
      expect(
        (await repository.updateSettings('03:00:00'))['refresh_time'],
        '03:00:00',
      );
    });

    test('exports and imports backup', () async {
      final client = FakeApiClient();
      client.onPost = (path, data) async {
        if (path == apiPath('/backup/export')) {
          return okResponse({
            'backup_id': 'b1',
            'data': {'decks': []},
          });
        }
        expect(path, apiPath('/backup/import'));
        expect(data, {
          'data': {'decks': []},
        });
        return okResponse({'imported_decks': 0});
      };
      final repository = SettingsRepository(client: client);

      expect((await repository.exportBackup())['backup_id'], 'b1');
      expect(
        (await repository.importBackup({'decks': []}))['imported_decks'],
        0,
      );
    });
  });
}
