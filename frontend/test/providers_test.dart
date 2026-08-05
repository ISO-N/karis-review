import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karisreview/auth/models/login_request.dart';
import 'package:karisreview/auth/models/login_response.dart';
import 'package:karisreview/auth/models/register_request.dart';
import 'package:karisreview/auth/providers/auth_provider.dart';
import 'package:karisreview/card/models/card.dart';
import 'package:karisreview/card/providers/card_provider.dart';
import 'package:karisreview/deck/models/deck.dart';
import 'package:karisreview/deck/providers/deck_provider.dart';
import 'package:karisreview/offline/database/app_database.dart';
import 'package:karisreview/offline/local_scheduling_engine.dart';
import 'package:karisreview/offline/offline_repository.dart';
import 'package:karisreview/review/models/review_card.dart';
import 'package:karisreview/review/providers/review_provider.dart';
import 'package:karisreview/review/repositories/review_repository.dart';
import 'package:karisreview/settings/providers/settings_provider.dart';
import 'package:karisreview/stats/models/stats.dart';
import 'package:karisreview/stats/providers/stats_provider.dart';
import 'package:karisreview/sync/repositories/sync_repository.dart';
import 'package:karisreview/sync/sync_service.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(
      LoginRequest(email: 'fallback@example.com', password: 'fallback'),
    );
    registerFallbackValue(
      RegisterRequest(
        email: 'fallback@example.com',
        password: 'fallback',
        verificationCode: '123456',
      ),
    );
  });

  group('AuthNotifier', () {
    test('login stores authenticated user', () async {
      final repo = MockAuthRepository();
      when(() => repo.isLoggedIn()).thenAnswer((_) async => false);
      when(() => repo.login(any())).thenAnswer(
        (_) async => LoginResponse.fromJson({
          'token': 't',
          'user': {'id': 'u1', 'email': 'a@b.c'},
        }),
      );
      final notifier = AuthNotifier(repo);

      await notifier.login('a@b.c', 'secret');

      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.user?.email, 'a@b.c');
      verify(() => repo.login(any())).called(1);
    });

    test('register forwards invite code', () async {
      final repo = MockAuthRepository();
      when(() => repo.isLoggedIn()).thenAnswer((_) async => false);
      when(() => repo.register(any())).thenAnswer(
        (_) async => LoginResponse.fromJson({
          'token': 't',
          'user': {'id': 'u1', 'email': 'a@b.c'},
        }),
      );
      final notifier = AuthNotifier(repo);

      await notifier.register(
        'a@b.c',
        'secret',
        inviteCode: 'code',
        verificationCode: '123456',
      );

      expect(notifier.state.isAuthenticated, isTrue);
      final captured = verify(() => repo.register(captureAny())).captured;
      final request = captured.single as RegisterRequest;
      expect(request.email, 'a@b.c');
      expect(request.inviteCode, 'code');
      expect(request.verificationCode, '123456');
    });

    test('login exposes backend error message', () async {
      final repo = MockAuthRepository();
      when(() => repo.isLoggedIn()).thenAnswer((_) async => false);
      when(() => repo.login(any())).thenThrow(apiError('邮箱已被注册'));
      final notifier = AuthNotifier(repo);

      await notifier.login('a@b.c', 'secret');

      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.error, '邮箱已被注册');
    });

    test('login exposes connection error detail', () async {
      final repo = MockAuthRepository();
      when(() => repo.isLoggedIn()).thenAnswer((_) async => false);
      when(
        () => repo.login(any()),
      ).thenThrow(connectionError('Connection refused, errno = 111'));
      final notifier = AuthNotifier(repo);

      await notifier.login('a@b.c', 'secret');

      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.error, contains('无法连接服务器'));
      expect(notifier.state.error, contains('Connection refused'));
    });

    test('logout clears state', () async {
      final repo = MockAuthRepository();
      when(() => repo.isLoggedIn()).thenAnswer((_) async => false);
      when(() => repo.login(any())).thenAnswer(
        (_) async => LoginResponse.fromJson({
          'token': 't',
          'user': {'id': 'u1', 'email': 'a@b.c'},
        }),
      );
      when(() => repo.logout()).thenAnswer((_) async {});
      final notifier = AuthNotifier(repo);
      await notifier.login('a@b.c', 'secret');

      await notifier.logout();

      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.user, isNull);
    });

    test('changePassword succeeds and logs out', () async {
      final repo = MockAuthRepository();
      when(() => repo.isLoggedIn()).thenAnswer((_) async => false);
      when(() => repo.login(any())).thenAnswer(
        (_) async => LoginResponse.fromJson({
          'token': 't',
          'user': {'id': 'u1', 'email': 'a@b.c'},
        }),
      );
      when(() => repo.changePassword(any(), any())).thenAnswer((_) async {});
      when(() => repo.logout()).thenAnswer((_) async {});
      final notifier = AuthNotifier(repo);
      await notifier.login('a@b.c', 'secret');

      await notifier.changePassword('old', 'new-password');

      // 修改成功后主动登出
      expect(notifier.state.isAuthenticated, isFalse);
      verify(() => repo.changePassword('old', 'new-password')).called(1);
      verify(() => repo.logout()).called(1);
    });

    test('changePassword exposes backend error without logout', () async {
      final repo = MockAuthRepository();
      when(() => repo.isLoggedIn()).thenAnswer((_) async => false);
      when(
        () => repo.changePassword(any(), any()),
      ).thenThrow(apiError('当前密码错误', statusCode: 400));
      final notifier = AuthNotifier(repo);

      await notifier.changePassword('wrong', 'new-password');

      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.error, '当前密码错误');
      verifyNever(() => repo.logout());
    });

    test('sendResetCode reports success', () async {
      final repo = MockAuthRepository();
      when(() => repo.isLoggedIn()).thenAnswer((_) async => false);
      when(() => repo.sendResetCode(any())).thenAnswer((_) async {});
      final notifier = AuthNotifier(repo);

      await notifier.sendResetCode('a@b.c');

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
      verify(() => repo.sendResetCode('a@b.c')).called(1);
    });

    test('resetPassword reports success', () async {
      final repo = MockAuthRepository();
      when(() => repo.isLoggedIn()).thenAnswer((_) async => false);
      when(() => repo.resetPassword(any(), any(), any())).thenAnswer((_) async {});
      final notifier = AuthNotifier(repo);

      await notifier.resetPassword('a@b.c', '123456', 'new-password');

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
      verify(() => repo.resetPassword('a@b.c', '123456', 'new-password')).called(1);
    });
  });

  group('DeckListNotifier', () {
    test('loads decks into data state', () async {
      final repo = MockDeckRepository();
      when(
        () => repo.getDecks(),
      ).thenAnswer((_) async => [Deck.fromJson(deckJson())]);
      final notifier = DeckListNotifier(repo);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.value, isNotNull);
      expect(notifier.state.value!.single.name, '日语 N5');
    });

    test('create reloads the list', () async {
      final repo = MockDeckRepository();
      when(() => repo.getDecks()).thenAnswer((_) async => []);
      when(
        () => repo.createDeck('新牌组'),
      ).thenAnswer((_) async => Deck.fromJson(deckJson(name: '新牌组')));
      final notifier = DeckListNotifier(repo);
      await Future<void>.delayed(Duration.zero);

      when(
        () => repo.getDecks(),
      ).thenAnswer((_) async => [Deck.fromJson(deckJson(name: '新牌组'))]);
      await notifier.createDeck('新牌组');

      expect(notifier.state.value!.single.name, '新牌组');
      verify(() => repo.createDeck('新牌组')).called(1);
    });
  });

  group('CardListNotifier', () {
    test('loads cards for the selected filter', () async {
      final repo = MockCardRepository();
      when(
        () => repo.getDeckCards('deck-1', size: 500, filter: 'all'),
      ).thenAnswer(
        (_) async => {
          'content': [cardJson()],
        },
      );
      final notifier = CardListNotifier(
        repo,
        const CardListArgs('deck-1', 'all'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.value, isNotNull);
      expect(notifier.state.value!.single.front, '正面');
    });

    test('search preserves previous list while loading', () async {
      final repo = MockCardRepository();
      when(
        () => repo.getDeckCards('deck-1', size: 500, filter: 'all'),
      ).thenAnswer(
        (_) async => {
          'content': [cardJson(id: 'old')],
        },
      );
      final notifier = CardListNotifier(
        repo,
        const CardListArgs('deck-1', 'all'),
      );
      await Future<void>.delayed(Duration.zero);

      final searchCompleter = Completer<Map<String, dynamic>>();
      when(
        () => repo.getDeckCards('deck-1', size: 500, filter: 'all', query: '词'),
      ).thenAnswer((_) => searchCompleter.future);

      final searchFuture = notifier.setSearchQuery('词');

      expect(notifier.state.value, hasLength(1));
      expect(notifier.state.value!.single.id, 'old');
      searchCompleter.complete({
        'content': [cardJson(id: 'new')],
        'total_pages': 1,
      });
      await searchFuture;

      expect(notifier.state.value!.single.id, 'new');
    });

    test('search loads all matching pages', () async {
      final repo = MockCardRepository();
      when(
        () => repo.getDeckCards('deck-1', size: 500, filter: 'all'),
      ).thenAnswer((_) async => {'content': []});
      final notifier = CardListNotifier(
        repo,
        const CardListArgs('deck-1', 'all'),
      );
      await Future<void>.delayed(Duration.zero);

      when(
        () => repo.getDeckCards('deck-1', size: 500, filter: 'all', query: '词'),
      ).thenAnswer(
        (_) async => {
          'content': [cardJson(id: 'card-1')],
          'total_pages': 2,
        },
      );
      when(
        () => repo.getDeckCards(
          'deck-1',
          page: 1,
          size: 500,
          filter: 'all',
          query: '词',
        ),
      ).thenAnswer(
        (_) async => {
          'content': [cardJson(id: 'card-2')],
          'total_pages': 2,
        },
      );

      await notifier.setSearchQuery('词');

      expect(notifier.state.value!.map((card) => card.id), [
        'card-1',
        'card-2',
      ]);
    });

    test('stale search response does not overwrite latest query', () async {
      final repo = MockCardRepository();
      when(
        () => repo.getDeckCards('deck-1', size: 500, filter: 'all'),
      ).thenAnswer(
        (_) async => {
          'content': [cardJson(id: 'base')],
        },
      );
      final notifier = CardListNotifier(
        repo,
        const CardListArgs('deck-1', 'all'),
      );
      await Future<void>.delayed(Duration.zero);

      final oldCompleter = Completer<Map<String, dynamic>>();
      final latestCompleter = Completer<Map<String, dynamic>>();
      when(
        () => repo.getDeckCards('deck-1', size: 500, filter: 'all', query: '旧'),
      ).thenAnswer((_) => oldCompleter.future);
      when(
        () => repo.getDeckCards('deck-1', size: 500, filter: 'all', query: '新'),
      ).thenAnswer((_) => latestCompleter.future);

      final firstSearch = notifier.setSearchQuery('旧');
      final secondSearch = notifier.setSearchQuery('新');
      oldCompleter.complete({
        'content': [cardJson(id: 'stale')],
        'total_pages': 1,
      });
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.value!.single.id, 'base');
      latestCompleter.complete({
        'content': [cardJson(id: 'latest')],
        'total_pages': 1,
      });
      await Future.wait([firstSearch, secondSearch]);

      expect(notifier.state.value!.single.id, 'latest');
    });

    test('create card reloads list', () async {
      final repo = MockCardRepository();
      when(
        () => repo.getDeckCards('deck-1', size: 500, filter: 'all'),
      ).thenAnswer((_) async => {'content': []});
      when(
        () => repo.createCard('deck-1', 'f', 'b'),
      ).thenAnswer((_) async => FlashCard.fromJson(cardJson()));
      final notifier = CardListNotifier(
        repo,
        const CardListArgs('deck-1', 'all'),
      );
      await Future<void>.delayed(Duration.zero);

      when(
        () => repo.getDeckCards('deck-1', size: 500, filter: 'all'),
      ).thenAnswer(
        (_) async => {
          'content': [cardJson()],
        },
      );
      await notifier.createCard('f', 'b');

      expect(notifier.state.value!.single.id, 'card-1');
    });

    test('deleteCards chunks requests and reloads', () async {
      final repo = MockCardRepository();
      when(
        () => repo.getDeckCards('deck-1', size: 500, filter: 'all'),
      ).thenAnswer(
        (_) async => {
          'content': [cardJson()],
        },
      );
      when(() => repo.batchDeleteCards(any())).thenAnswer((_) async {});
      final notifier = CardListNotifier(
        repo,
        const CardListArgs('deck-1', 'all'),
      );
      await Future<void>.delayed(Duration.zero);

      when(
        () => repo.getDeckCards('deck-1', size: 500, filter: 'all'),
      ).thenAnswer((_) async => {'content': []});

      final ids = List.generate(1001, (index) => 'card-$index');
      await notifier.deleteCards(ids);

      verify(() => repo.batchDeleteCards(any())).called(2);
      expect(notifier.state.value, isEmpty);
    });
  });

  group('ReviewNotifier', () {
    test('loads due queue and supports flip and rating', () async {
      final repo = MockReviewRepository();
      when(
        () => repo.getDueCards(deckId: null),
      ).thenAnswer((_) async => [ReviewCard.fromJson(reviewCardJson())]);
      when(
        () => repo.rateCard('card-1', 'FAMILIAR'),
      ).thenAnswer((_) async => ReviewResult.fromJson(reviewResultJson()));
      final notifier = ReviewNotifier(repo);

      await notifier.loadQueue(mode: 'due');
      expect(notifier.state.cards, hasLength(1));

      notifier.flip();
      expect(notifier.state.isFlipped, isTrue);

      await notifier.rate('FAMILIAR');
      expect(notifier.state.currentIndex, 1);
      expect(notifier.state.reviewedCount, 1);
      expect(notifier.state.isComplete, isTrue);
    });
    test('server session keeps total count from page total', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final offline = OfflineRepository(db);
      await offline.saveBootstrap(
        userId: 'user-1',
        email: 'a@b.c',
        refreshTime: '04:00:00',
        serverTime: DateTime.utc(2025, 8, 2, 12),
        decks: [],
        reviewLogs: [],
      );

      final api = FakeApiClient();
      api.onPostProto = (_, _, _) async {
        throw apiError('unsupported', statusCode: 415);
      };
      api.onPost = (_, _) async => okResponse({
        'session_id': 'session-1',
        'mode': 'due',
        'deck_id': null,
        'batch_size': 10,
        'total': 25,
        'cursor': 10,
        'has_more': true,
        'cards': [
          for (var i = 0; i < 10; i++)
            reviewCardJson(id: 'card-$i', front: '正面 $i'),
        ],
      });

      final notifier = ReviewNotifier(
        ReviewRepository(),
        offline: offline,
        sync: SyncRepository(client: api),
        syncService: SyncService(SyncRepository(client: api), offline),
      );
      await notifier.loadQueue(mode: 'due');

      expect(notifier.state.cards, hasLength(10));
      expect(notifier.state.serverTotal, 25);
      expect(notifier.state.totalCount, 25);
      expect(notifier.state.sessionTotal, 25);
      await db.close();
    });

    test('uses local queue when pending ratings still cannot sync', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final offline = OfflineRepository(db);
      await offline.saveBootstrap(
        userId: 'user-1',
        email: 'a@b.c',
        refreshTime: '04:00:00',
        serverTime: DateTime.utc(2025, 8, 2, 12),
        decks: [
          {
            'id': 'deck-1',
            'name': '日语',
            'created_at': '2025-08-01T00:00:00Z',
            'updated_at': '2025-08-01T00:00:00Z',
            'cards': [
              {
                'id': 'card-1',
                'deck_id': 'deck-1',
                'front': '单词',
                'back': '释义',
                'stage': 2,
                'consecutive_familiar': 0,
                'next_review_date': '2025-08-02',
                'learning_mode': false,
                'reentry_stage': null,
                'learning_step': 0,
                'review_version': 2,
                'created_at': '2025-08-01T00:00:00Z',
                'updated_at': '2025-08-02T00:00:00Z',
              },
            ],
          },
        ],
        reviewLogs: [],
      );

      final card = FlashCard(
        id: 'card-1',
        deckId: 'deck-1',
        front: '单词',
        back: '释义',
        stage: 2,
        nextReviewDate: '2025-08-02',
        learningMode: false,
        reviewVersion: 2,
      );
      final outcome = LocalSchedulingEngine().rate(
        card,
        'FORGET',
        nowUtc: DateTime.utc(2025, 8, 2, 12),
        refreshTime: '04:00:00',
      );
      await offline.applyLocalRating(
        userId: 'user-1',
        card: outcome.card,
        result: outcome.result,
        clientRequestId: 'request-1',
        ratedAt: DateTime.utc(2025, 8, 2, 12),
        reviewVersionBefore: outcome.reviewVersionBefore,
        isNewCard: outcome.wasNewCard,
      );

      var sessionCalls = 0;
      final api = FakeApiClient();
      api.onPostProto = (path, query, body) async {
        if (path.endsWith('/review/sync')) {
          throw apiError('同步失败', statusCode: 500);
        }
        if (path.endsWith('/review/sessions')) {
          sessionCalls += 1;
          throw StateError('不应在待同步时创建服务端会话');
        }
        throw StateError('未预期的请求');
      };

      final sync = SyncService(SyncRepository(client: api), offline);
      final notifier = ReviewNotifier(
        ReviewRepository(),
        offline: offline,
        sync: SyncRepository(client: api),
        syncService: sync,
      );
      await notifier.loadQueue(mode: 'due');

      expect(notifier.state.queueSource, 'local');
      expect(notifier.state.cards, hasLength(1));
      expect(notifier.state.cards.single.id, 'card-1');
      expect(notifier.state.pendingSyncCount, 1);
      expect(sessionCalls, 0);
      await db.close();
    });
    test('loads all new cards without a limit', () async {
      final repo = MockReviewRepository();
      when(() => repo.getNewCards(deckId: null)).thenAnswer(
        (_) async => [
          for (var i = 0; i < 3; i++)
            ReviewCard.fromJson(reviewCardJson(id: 'new-$i')),
        ],
      );
      final notifier = ReviewNotifier(repo);

      await notifier.loadQueue(mode: 'new');

      expect(notifier.state.cards, hasLength(3));
    });

    test('rating error does not advance index', () async {
      final repo = MockReviewRepository();
      when(
        () => repo.getDueCards(deckId: null),
      ).thenAnswer((_) async => [ReviewCard.fromJson(reviewCardJson())]);
      when(
        () => repo.rateCard('card-1', 'FAMILIAR'),
      ).thenThrow(apiError('评分失败'));
      final notifier = ReviewNotifier(repo);
      await notifier.loadQueue(mode: 'due');

      final result = await notifier.rate('FAMILIAR');

      expect(result, isNull);
      expect(notifier.state.currentIndex, 0);
      expect(notifier.state.error, '评分失败，请检查网络后重试');
      expect(notifier.state.ratingFailed, isTrue);
    });
  });

  group('StatsNotifier', () {
    test('loads overview stats', () async {
      final repo = MockStatsRepository();
      when(
        () => repo.getOverview(),
      ).thenAnswer((_) async => OverviewStats.fromJson(overviewStatsJson()));
      final notifier = StatsNotifier(repo);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.value?.totalCards, 10);
    });

    test('stores error when overview fails', () async {
      final repo = MockStatsRepository();
      when(() => repo.getOverview()).thenThrow(apiError('统计失败'));
      final notifier = StatsNotifier(repo);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state, isA<AsyncError<OverviewStats?>>());
    });
  });

  group('SettingsNotifier', () {
    test('loads and updates settings', () async {
      final repo = MockSettingsRepository();
      when(
        () => repo.getSettings(),
      ).thenAnswer((_) async => {'email': 'a@b.c', 'refresh_time': '04:00:00'});
      when(
        () => repo.updateSettings('03:00:00'),
      ).thenAnswer((_) async => {'email': 'a@b.c', 'refresh_time': '03:00:00'});
      final notifier = SettingsNotifier(repo);
      await Future<void>.delayed(Duration.zero);

      await notifier.updateSettings('03:00:00');

      expect(notifier.state.refreshTime, '03:00:00');
      expect(notifier.state.isSaved, isTrue);
    });
  });
}
