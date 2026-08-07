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

/// 带离线仓库与同步服务的评分测试桩：初始队列直接注入，不走 loadQueue。
class _RelearnNotifier extends ReviewNotifier {
  _RelearnNotifier(
    super.repository, {
    super.offline,
    super.sync,
    super.syncService,
    required ReviewSessionState initial,
  }) {
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

  test('FORGET 后重学卡实时插回队列，无需退出重进', () async {
    await _seedMeta(offline);
    final api = FakeApiClient();
    final notifier = _RelearnNotifier(
      ReviewRepository(),
      offline: offline,
      sync: SyncRepository(client: api),
      syncService: SyncService(SyncRepository(client: api), offline),
      initial: ReviewSessionState(
        mode: 'due',
        cards: [
          ReviewCard.fromJson(reviewCardJson(id: 'card-a', front: 'A')),
        ],
        currentIndex: 0,
      ),
    );

    final result = await notifier.rate('FORGET');

    expect(result, isNotNull);
    expect(result!.learningMode, isTrue);
    // 队列评完原卡后重学卡立即就位，不进入完成态。
    expect(notifier.state.cards, hasLength(2));
    expect(notifier.state.cards[1].id, 'card-a');
    expect(notifier.state.cards[1].learningMode, isTrue);
    expect(notifier.state.cards[1].learningStep, 0);
    expect(notifier.state.currentIndex, 1);
    expect(notifier.state.isComplete, isFalse);
    notifier.dispose();
  });

  test('重学卡按 2^n 位置插入，步长越大间隔越远', () async {
    await _seedMeta(offline);
    final api = FakeApiClient();
    final notifier = _RelearnNotifier(
      ReviewRepository(),
      offline: offline,
      sync: SyncRepository(client: api),
      syncService: SyncService(SyncRepository(client: api), offline),
      initial: ReviewSessionState(
        mode: 'due',
        cards: [
          ReviewCard.fromJson(reviewCardJson(id: 'card-a', front: 'A')),
          ReviewCard.fromJson(reviewCardJson(id: 'card-b', front: 'B')),
          ReviewCard.fromJson(reviewCardJson(id: 'card-c', front: 'C')),
        ],
        currentIndex: 0,
      ),
    );

    // 评 A FORGET：learningStep=0 → 插到 currentIndex+1（紧邻）。
    await notifier.rate('FORGET');
    expect(
      notifier.state.cards.map((c) => c.id),
      ['card-a', 'card-b', 'card-a', 'card-c'],
    );
    expect(notifier.state.currentIndex, 1);

    // 评 B FORGET：同样紧邻插回。
    await notifier.rate('FORGET');
    expect(
      notifier.state.cards.map((c) => c.id),
      ['card-a', 'card-b', 'card-a', 'card-b', 'card-c'],
    );
    expect(notifier.state.currentIndex, 2);

    // 当前卡是重学 A（learningStep=0），FAMILIAR 未达标 → learningStep=1。
    await notifier.rate('FAMILIAR');
    expect(
      notifier.state.cards.map((c) => c.id),
      ['card-a', 'card-b', 'card-a', 'card-b', 'card-c', 'card-a'],
    );
    expect(notifier.state.cards[5].learningStep, 1);
    expect(notifier.state.currentIndex, 3);
    notifier.dispose();
  });

  test('FAMILIAR 达标脱离学习后不再插回', () async {
    await _seedMeta(offline);
    final api = FakeApiClient();
    final notifier = _RelearnNotifier(
      ReviewRepository(),
      offline: offline,
      sync: SyncRepository(client: api),
      syncService: SyncService(SyncRepository(client: api), offline),
      initial: ReviewSessionState(
        mode: 'due',
        cards: [
          ReviewCard(
            id: 'card-a',
            deckId: 'deck-1',
            front: 'A',
            back: 'b',
            stage: 0,
            learningMode: true,
            consecutiveFamiliar: 4,
            learningStep: 4,
            nextReviewDate: '2026-08-07',
            reviewVersion: 5,
          ),
        ],
        currentIndex: 0,
      ),
    );

    final result = await notifier.rate('FAMILIAR');

    expect(result, isNotNull);
    expect(result!.learningMode, isFalse);
    expect(notifier.state.cards, hasLength(1));
    expect(notifier.state.currentIndex, 1);
    expect(notifier.state.isComplete, isTrue);
    // 等待 isComplete 触发的后台同步完成，避免其访问已关闭的数据库。
    await pumpEventQueue();
    notifier.dispose();
  });
}
