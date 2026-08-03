import 'package:drift/native.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karisreview/card/models/card.dart';
import 'package:karisreview/offline/database/app_database.dart';
import 'package:karisreview/offline/local_scheduling_engine.dart';
import 'package:karisreview/offline/offline_repository.dart';
import 'package:karisreview/shared/proto/karis_review.pb.dart' as proto;
import 'package:karisreview/sync/repositories/sync_repository.dart';
import 'package:karisreview/sync/sync_service.dart';

import 'helpers/test_helpers.dart';

Future<void> _seedCards(OfflineRepository offline) async {
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
          _cardMap('card-1', '一'),
          _cardMap('card-2', '二'),
          _cardMap('card-3', '三'),
          _cardMap('card-4', '四'),
        ],
      },
    ],
    reviewLogs: [],
    eventCursor: 1,
  );
}

Future<void> _pendingRating(
  OfflineRepository offline,
  String cardId,
  String clientRequestId,
) async {
  final card = FlashCard(
    id: cardId,
    deckId: 'deck-1',
    front: '正面 $cardId',
    back: '反面',
    stage: 0,
    learningMode: false,
    reviewVersion: 0,
  );
  final outcome = LocalSchedulingEngine().rate(
    card,
    'FAMILIAR',
    nowUtc: DateTime.utc(2025, 8, 2, 12),
    refreshTime: '04:00:00',
  );
  await offline.applyLocalRating(
    userId: 'user-1',
    card: outcome.card,
    result: outcome.result,
    clientRequestId: clientRequestId,
    ratedAt: DateTime.utc(2025, 8, 2, 12),
    reviewVersionBefore: outcome.reviewVersionBefore,
    isNewCard: outcome.wasNewCard,
  );
}

Map<String, dynamic> _cardMap(String id, String front) {
  return {
    'id': id,
    'deck_id': 'deck-1',
    'front': front,
    'back': '反面',
    'stage': 0,
    'consecutive_familiar': 0,
    'next_review_date': null,
    'learning_mode': false,
    'reentry_stage': null,
    'learning_step': 0,
    'review_version': 0,
    'created_at': '2025-08-01T00:00:00Z',
    'updated_at': '2025-08-01T00:00:00Z',
  };
}

void main() {
  late AppDatabase db;
  late OfflineRepository offline;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    offline = OfflineRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('syncPending applies synced, conflict and missing outcomes', () async {
    await _seedCards(offline);
    await _pendingRating(offline, 'card-1', 'req-1');
    await _pendingRating(offline, 'card-2', 'req-2');
    await _pendingRating(offline, 'card-3', 'req-3');
    await _pendingRating(offline, 'card-4', 'req-4');

    final api = FakeApiClient();
    api.onPostProto = (_, _, _) async {
      return proto.ReviewSyncResponse(
        synced: 2,
        conflicts: 1,
        missing: 1,
        items: [
          proto.ReviewSyncItemResult(clientRequestId: 'req-1', status: 'SYNCED'),
          proto.ReviewSyncItemResult(
              clientRequestId: 'req-2', status: 'ALREADY_SYNCED'),
          proto.ReviewSyncItemResult(
            clientRequestId: 'req-3',
            status: 'CONFLICT',
            currentCard: proto.ReviewCard(
              id: 'card-3',
              deckId: 'deck-1',
              front: '正面',
              back: '反面',
              stage: 1,
              reviewVersion: Int64(2),
            ),
          ),
          proto.ReviewSyncItemResult(
              clientRequestId: 'req-4', status: 'CARD_NOT_FOUND'),
        ],
      ).writeToBuffer();
    };
    final sync = SyncService(SyncRepository(client: api), offline);

    final outcome = await sync.syncPending(userId: 'user-1');

    expect(outcome.synced, 2);
    expect(outcome.conflicts, 1);
    expect(outcome.missing, 1);
    expect(await offline.getPendingRatings('user-1'), isEmpty);

    final rows = await db.select(db.localReviewLogs).get();
    final statusById = {for (final row in rows) row.clientRequestId: row.syncStatus};
    expect(statusById['req-1'], 'SYNCED');
    expect(statusById['req-2'], 'SYNCED');
    expect(statusById['req-3'], 'DISCARDED');
    expect(statusById['req-4'], 'DISCARDED');

    expect((await offline.getLocalCard('user-1', 'card-3'))?.stage, 1);
    expect(await offline.getLocalCard('user-1', 'card-4'), isNull);
  });

  test('refresh falls back to full bootstrap when reset is required', () async {
    await offline.saveBootstrap(
      userId: 'user-1',
      email: 'a@b.c',
      refreshTime: '04:00:00',
      serverTime: DateTime.utc(2025, 8, 2, 12),
      decks: [],
      reviewLogs: [],
      eventCursor: 5,
    );

    var getProtoCalls = 0;
    final api = FakeApiClient();
    api.onGetProto = (_, query) async {
      getProtoCalls += 1;
      if (query?['event_cursor'] == 5) {
        return proto.SyncResponse(
          serverTime: '2025-08-02T12:00:01Z',
          user: proto.User(
            id: 'user-1',
            email: 'a@b.c',
            refreshTime: '04:00:00',
          ),
          eventCursor: Int64(5),
          resetRequired: true,
        ).writeToBuffer();
      }
      return proto.SyncResponse(
        serverTime: '2025-08-02T12:00:02Z',
        user: proto.User(
          id: 'user-1',
          email: 'a@b.c',
          refreshTime: '04:00:00',
        ),
        decks: [
          proto.Deck(
            id: 'deck-2',
            name: '全量卡组',
            createdAt: '2025-08-01T00:00:00Z',
            updatedAt: '2025-08-01T00:00:00Z',
          ),
        ],
        eventCursor: Int64(9),
      ).writeToBuffer();
    };
    final sync = SyncService(SyncRepository(client: api), offline);
    expect(await offline.getActiveSyncMeta(), isNotNull);
    await sync.refresh();

    expect(getProtoCalls, 2);
    final decks = await offline.getDecks('user-1');
    expect(decks.map((d) => d.id), ['deck-2']);
    final meta = await offline.getSyncMeta('user-1');
    expect(meta?.lastEventCursor.toInt(), 9);
  });

  test('forceServerAuthoritative discards pending and reloads full data', () async {
    await _seedCards(offline);
    await _pendingRating(offline, 'card-1', 'req-force');

    final api = FakeApiClient();
    api.onGetProto = (_, _) async {
      return proto.SyncResponse(
        serverTime: '2025-08-02T12:00:03Z',
        user: proto.User(
          id: 'user-1',
          email: 'a@b.c',
          refreshTime: '04:00:00',
        ),
        decks: [
          proto.Deck(
            id: 'deck-3',
            name: '服务器数据',
            createdAt: '2025-08-01T00:00:00Z',
            updatedAt: '2025-08-01T00:00:00Z',
          ),
        ],
        eventCursor: Int64(4),
      ).writeToBuffer();
    };
    final sync = SyncService(SyncRepository(client: api), offline);

    await sync.forceServerAuthoritative(userId: 'user-1');

    expect(await offline.getPendingRatings('user-1'), isEmpty);
    final decks = await offline.getDecks('user-1');
    expect(decks.map((d) => d.id), ['deck-3']);
  });
}
