import 'package:drift/native.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karisreview/offline/database/app_database.dart';
import 'package:karisreview/offline/offline_repository.dart';
import 'package:karisreview/review/models/review_card.dart';
import 'package:karisreview/review/providers/review_provider.dart';
import 'package:karisreview/review/repositories/review_repository.dart';
import 'package:karisreview/shared/proto/karis_review.pb.dart' as proto;
import 'package:karisreview/sync/repositories/sync_repository.dart';
import 'package:karisreview/sync/sync_service.dart';

import 'helpers/test_helpers.dart';

class _StaticReviewNotifier extends ReviewNotifier {
  _StaticReviewNotifier(super.repository, ReviewSessionState initial) {
    state = initial;
  }

  @override
  Future<void> loadQueue({
    required String mode,
    String? deckId,
    int limit = 10,
  }) async {}
}

proto.ReviewCard _reviewCard(String id) {
  return proto.ReviewCard(
    id: id,
    deckId: 'deck-1',
    front: '正面 $id',
    back: '反面',
    stage: 0,
    reviewVersion: Int64(0),
  );
}

Future<void> _seedMeta(OfflineRepository offline) async {
  await offline.saveBootstrap(
    userId: 'user-1',
    email: 'a@b.c',
    refreshTime: '04:00:00',
    serverTime: DateTime.utc(2025, 8, 2, 12),
    decks: [],
    reviewLogs: [],
    eventCursor: 1,
  );
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

  test('loadMore appends pages and deduplicates cards', () async {
    await _seedMeta(offline);
    final api = FakeApiClient();
    api.onPostProto = (_, _, _) async {
      return proto.ReviewSessionPageResponse(
        sessionId: 'session-1',
        mode: 'due',
        batchSize: 10,
        total: 25,
        cursor: 10,
        hasMore: true,
        cards: [for (var i = 0; i < 10; i++) _reviewCard('card-$i')],
      ).writeToBuffer();
    };
    api.onGetProto = (_, query) async {
      final cursor = query?['cursor'];
      if (cursor == 10) {
        return proto.ReviewSessionPageResponse(
          sessionId: 'session-1',
          mode: 'due',
          total: 25,
          cursor: 20,
          hasMore: true,
          cards: [for (var i = 9; i < 20; i++) _reviewCard('card-$i')],
        ).writeToBuffer();
      }
      expect(cursor, 20);
      return proto.ReviewSessionPageResponse(
        sessionId: 'session-1',
        mode: 'due',
        total: 25,
        cursor: 25,
        hasMore: false,
        cards: [for (var i = 20; i < 25; i++) _reviewCard('card-$i')],
      ).writeToBuffer();
    };
    final notifier = ReviewNotifier(
      ReviewRepository(),
      offline: offline,
      sync: SyncRepository(client: api),
      syncService: SyncService(SyncRepository(client: api), offline),
    );

    await notifier.loadQueue(mode: 'due');
    await notifier.loadMore();
    await notifier.loadMore();

    expect(notifier.state.cards, hasLength(25));
    expect(notifier.state.cursor, 25);
    expect(notifier.state.hasMore, isFalse);
    expect(notifier.state.serverTotal, 25);
    expect(notifier.state.cards.map((c) => c.id).toSet(), hasLength(25));
  });

  test('loadMore fallback appends local queue when page fetch fails', () async {
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
              'id': 'local-due',
              'deck_id': 'deck-1',
              'front': '本地到期',
              'back': '反面',
              'stage': 2,
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
    final api = FakeApiClient();
    api.onPostProto = (_, _, _) async {
      return proto.ReviewSessionPageResponse(
        sessionId: 'session-2',
        mode: 'due',
        total: 25,
        cursor: 10,
        hasMore: true,
        cards: [_reviewCard('server-card')],
      ).writeToBuffer();
    };
    api.onGetProto = (_, _) async => throw apiError('分页失败');
    final notifier = ReviewNotifier(
      ReviewRepository(),
      offline: offline,
      sync: SyncRepository(client: api),
      syncService: SyncService(SyncRepository(client: api), offline),
    );

    await notifier.loadQueue(mode: 'due');
    await Future<void>.delayed(Duration.zero);
    await notifier.loadMore();

    expect(notifier.state.cards.map((c) => c.id), contains('local-due'));
    expect(notifier.state.queueSource, 'local');
    expect(notifier.state.hasMore, isFalse);
  });

  test('removeStaleCard adjusts current index', () {
    final notifier = _StaticReviewNotifier(
      ReviewRepository(),
      ReviewSessionState(
        cards: [
          ReviewCard.fromJson(reviewCardJson(id: 'card-0')),
          ReviewCard.fromJson(reviewCardJson(id: 'card-1')),
          ReviewCard.fromJson(reviewCardJson(id: 'card-2')),
        ],
        currentIndex: 2,
      ),
    );

    notifier.removeStaleCard('card-1');

    expect(notifier.state.cards.map((c) => c.id), ['card-0', 'card-2']);
    expect(notifier.state.currentIndex, 1);
  });
}
