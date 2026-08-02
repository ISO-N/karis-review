import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karisreview/auth/models/login_request.dart';
import 'package:karisreview/auth/models/login_response.dart';
import 'package:karisreview/auth/providers/auth_provider.dart';
import 'package:karisreview/card/models/card.dart';
import 'package:karisreview/card/providers/card_provider.dart';
import 'package:karisreview/deck/models/deck.dart';
import 'package:karisreview/deck/providers/deck_provider.dart';
import 'package:karisreview/review/models/review_card.dart';
import 'package:karisreview/review/providers/review_provider.dart';
import 'package:karisreview/settings/providers/settings_provider.dart';
import 'package:karisreview/stats/models/stats.dart';
import 'package:karisreview/stats/providers/stats_provider.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(
      LoginRequest(email: 'fallback@example.com', password: 'fallback'),
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

    test('login exposes backend error message', () async {
      final repo = MockAuthRepository();
      when(() => repo.isLoggedIn()).thenAnswer((_) async => false);
      when(() => repo.login(any())).thenThrow(apiError('邮箱已被注册'));
      final notifier = AuthNotifier(repo);

      await notifier.login('a@b.c', 'secret');

      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.error, '邮箱已被注册');
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
      expect(notifier.state.error, isNotNull);
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
