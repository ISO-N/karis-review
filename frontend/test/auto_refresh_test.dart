import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karisreview/card/providers/card_provider.dart';
import 'package:karisreview/deck/providers/deck_provider.dart';
import 'package:karisreview/offline/database/app_database.dart';
import 'package:karisreview/offline/offline_repository.dart';
import 'package:karisreview/offline/providers.dart';
import 'package:karisreview/review/models/review_card.dart';
import 'package:karisreview/review/providers/review_provider.dart';
import 'package:karisreview/shared/navigation/auto_refresh_observer.dart';
import 'package:karisreview/shared/proto/karis_review.pb.dart' as proto;
import 'package:karisreview/shared/providers/data_refresh_provider.dart';
import 'package:karisreview/shared/utils/daily_refresh.dart';
import 'package:karisreview/stats/providers/deck_stats_provider.dart';
import 'package:karisreview/stats/providers/stats_provider.dart';
import 'package:karisreview/sync/repositories/sync_repository.dart';
import 'package:karisreview/sync/sync_service.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/test_helpers.dart';

Future<void> _seedDueCard(OfflineRepository offline) async {
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
            'front': '正面',
            'back': '反面',
            'stage': 1,
            'consecutive_familiar': 0,
            'next_review_date': '2025-08-02',
            'learning_mode': false,
            'reentry_stage': null,
            'learning_step': 0,
            'review_version': 1,
            'created_at': '2025-08-01T00:00:00Z',
            'updated_at': '2025-08-01T00:00:00Z',
          },
        ],
      },
    ],
    reviewLogs: [],
    eventCursor: 1,
  );
}

Future<void> _moveCardToFuture(OfflineRepository offline) async {
  await offline.applyDelta(
    userId: 'user-1',
    data: {
      'decks': [],
      'changed_cards': [
        {
          'id': 'card-1',
          'deck_id': 'deck-1',
          'front': '正面',
          'back': '反面',
          'stage': 1,
          'consecutive_familiar': 0,
          'next_review_date': '2025-08-03',
          'learning_mode': false,
          'reentry_stage': null,
          'learning_step': 0,
          'review_version': 2,
          'created_at': '2025-08-01T00:00:00Z',
          'updated_at': '2025-08-02T12:00:00Z',
        },
      ],
      'review_logs': [],
      'deleted_deck_ids': [],
      'deleted_card_ids': [],
      'deleted_review_log_ids': [],
      'event_cursor': 2,
      'has_more': false,
      'reset_required': false,
    },
  );
}

Future<void> _waitUntil(bool Function() ready) async {
  for (var i = 0; i < 100; i++) {
    if (ready()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('等待自动刷新超时');
}

class _RatedNotifier extends ReviewNotifier {
  _RatedNotifier(
    super.repository,
    ReviewSessionState initial, {
    super.onDataChanged,
  }) {
    state = initial;
  }
}

void main() {
  group('nextDailyRefreshDelay', () {
    test('uses today boundary before refresh time', () {
      expect(
        nextDailyRefreshDelay(DateTime(2025, 1, 1, 3), '04:00:00'),
        const Duration(hours: 1),
      );
    });

    test('uses tomorrow boundary at or after refresh time', () {
      expect(
        nextDailyRefreshDelay(DateTime(2025, 1, 1, 4), '04:00:00'),
        const Duration(hours: 24),
      );
      expect(
        nextDailyRefreshDelay(DateTime(2025, 1, 1, 5), '04:00:00'),
        const Duration(hours: 23),
      );
    });

    test('supports custom refresh time', () {
      expect(
        nextDailyRefreshDelay(DateTime(2025, 1, 1, 3, 29), '03:30:00'),
        const Duration(minutes: 1),
      );
      expect(
        nextDailyRefreshDelay(DateTime(2025, 1, 1, 3, 31), '03:30:00'),
        const Duration(hours: 23, minutes: 59),
      );
    });
  });

  group('DataRefreshController', () {
    test('rating success notifies local data change', () async {
      final repo = MockReviewRepository();
      when(
        () => repo.rateCard('card-1', 'FAMILIAR'),
      ).thenAnswer((_) async => ReviewResult.fromJson(reviewResultJson()));
      var changes = 0;
      final notifier = _RatedNotifier(
        repo,
        ReviewSessionState(cards: [ReviewCard.fromJson(reviewCardJson())]),
        onDataChanged: () => changes += 1,
      );

      final result = await notifier.rate('FAMILIAR');

      expect(result, isNotNull);
      expect(changes, 1);
    });

    test('notifyLocalChanged never touches the network', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final offline = OfflineRepository(db);
      var changes = 0;
      final api = FakeApiClient();
      api.onGetProto = (_, _) async => throw StateError('不应发起同步');

      final controller = DataRefreshController(
        SyncService(SyncRepository(client: api), offline),
        offline,
        () => changes++,
      );

      controller.notifyLocalChanged();
      expect(changes, 1);
    });

    test('refreshFromServer syncs and is bounded by sync cooldown', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final offline = OfflineRepository(db);
      await _seedDueCard(offline);

      var syncCalls = 0;
      var changes = 0;
      final api = FakeApiClient();
      api.onGetProto = (_, _) async {
        syncCalls += 1;
        return proto.SyncResponse(
          serverTime: '2025-08-02T12:00:01Z',
          user: proto.User(
            id: 'user-1',
            email: 'a@b.c',
            refreshTime: '04:00:00',
          ),
          hasMore: false,
        ).writeToBuffer();
      };
      final controller = DataRefreshController(
        SyncService(SyncRepository(client: api), offline),
        offline,
        () => changes++,
      );

      await controller.refreshFromServer();
      expect(syncCalls, 1);
      expect(changes, 1);

      await controller.refreshFromServer();
      expect(syncCalls, 1);
      expect(changes, 2);
    });
  });

  group('auto refresh providers', () {
    late AppDatabase db;
    late OfflineRepository offline;
    late ProviderContainer container;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      offline = OfflineRepository(db);
      await _seedDueCard(offline);
      container = ProviderContainer(
        overrides: [offlineRepositoryProvider.overrideWithValue(offline)],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('version bump refreshes overview and deck stats', () async {
      await _waitUntil(() => container.read(statsProvider).hasValue);
      await _waitUntil(
        () => container.read(deckStatsProvider('deck-1')).hasValue,
      );
      expect(container.read(statsProvider).value?.dueToday, 1);
      expect(container.read(deckStatsProvider('deck-1')).value?.dueToday, 1);

      await _moveCardToFuture(offline);
      container.read(dataVersionProvider.notifier).state++;
      await _waitUntil(
        () => container.read(statsProvider).value?.dueToday == 0,
      );
      await _waitUntil(
        () => container.read(deckStatsProvider('deck-1')).value?.dueToday == 0,
      );

      expect(container.read(deckStatsProvider('deck-1')).value?.dueToday, 0);
    });

    test('version bump refreshes deck summaries and card list', () async {
      await _waitUntil(() => container.read(deckListProvider).hasValue);
      await _waitUntil(
        () => container
            .read(cardListProvider(const CardListArgs('deck-1', 'due')))
            .hasValue,
      );
      expect(container.read(deckListProvider).value?.single.dueCount, 1);
      expect(
        container
            .read(cardListProvider(const CardListArgs('deck-1', 'due')))
            .value,
        hasLength(1),
      );

      await _moveCardToFuture(offline);
      container.read(dataVersionProvider.notifier).state++;
      await _waitUntil(
        () => container.read(deckListProvider).value?.single.dueCount == 0,
      );

      expect(
        container
            .read(cardListProvider(const CardListArgs('deck-1', 'due')))
            .value,
        isEmpty,
      );
    });
  });

  testWidgets('navigator observer refreshes after push and pop', (
    tester,
  ) async {
    var calls = 0;
    final observer = AutoRefreshNavigatorObserver(
      onDataRouteChanged: () async => calls += 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('返回'),
                    ),
                  ),
                ),
              ),
            ),
            child: const Text('打开'),
          ),
        ),
      ),
    );
    await tester.pump();

    final initial = calls;
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(calls, greaterThan(initial));

    final afterPush = calls;
    await tester.tap(find.text('返回'));
    await tester.pumpAndSettle();
    expect(calls, greaterThan(afterPush));
  });
}
