import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karisreview/card/models/card.dart';
import 'package:karisreview/offline/database/app_database.dart';
import 'package:karisreview/offline/local_scheduling_engine.dart';
import 'package:karisreview/offline/offline_repository.dart';
import 'package:karisreview/review/models/review_card.dart';
import 'package:karisreview/shared/proto/karis_review.pb.dart' as proto;
import 'package:karisreview/sync/repositories/sync_repository.dart';
import 'package:karisreview/sync/sync_service.dart';

import 'helpers/test_helpers.dart';

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

  test('bootstrap populates local decks and queues', () async {
    await offline.saveBootstrap(
      userId: 'user-1',
      email: 'a@b.c',
      refreshTime: '04:00:00',
      serverTime: DateTime.now().toUtc(),
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
              'stage': 0,
              'consecutive_familiar': 0,
              'next_review_date': null,
              'learning_mode': false,
              'reentry_stage': null,
              'learning_step': 0,
              'review_version': 0,
              'created_at': '2025-08-01T00:00:00Z',
              'updated_at': '2025-08-01T00:00:00Z',
            },
          ],
        },
      ],
      reviewLogs: [],
    );

    final newQueue = await offline.getNewQueue('user-1');
    expect(newQueue, hasLength(1));
    expect(newQueue.single.front, '单词');
    expect(newQueue.single.reviewVersion, 0);

    final summaries = await offline.getDeckSummaries('user-1');
    expect(summaries.single.cardCount, 1);
  });

  test('local rating creates pending log and increments card version', () async {
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
              'stage': 0,
              'consecutive_familiar': 0,
              'next_review_date': null,
              'learning_mode': false,
              'reentry_stage': null,
              'learning_step': 0,
              'review_version': 0,
              'created_at': '2025-08-01T00:00:00Z',
              'updated_at': '2025-08-01T00:00:00Z',
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
      clientRequestId: 'request-1',
      ratedAt: DateTime.utc(2025, 8, 2, 12),
      reviewVersionBefore: outcome.reviewVersionBefore,
      isNewCard: outcome.wasNewCard,
    );

    final pending = await offline.getPendingRatings('user-1');
    expect(pending, hasLength(1));
    expect(pending.single.reviewVersion.toInt(), 0);
    expect(pending.single.isNewCard, isTrue);

    final overview = await offline.getOverviewStats('user-1');
    expect(overview.learnedToday, 1);
    expect(overview.reviewedToday, 0);

    final localCard = await offline.getLocalCard('user-1', 'card-1');
    expect(localCard?.reviewVersion.toInt(), 1);
    expect(localCard?.stage, 1);
  });

  test('server card does not overwrite a pending local rating', () async {
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
              'stage': 0,
              'consecutive_familiar': 0,
              'next_review_date': null,
              'learning_mode': false,
              'reentry_stage': null,
              'learning_step': 0,
              'review_version': 0,
              'created_at': '2025-08-01T00:00:00Z',
              'updated_at': '2025-08-01T00:00:00Z',
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
      clientRequestId: 'request-1',
      ratedAt: DateTime.utc(2025, 8, 2, 12),
      reviewVersionBefore: outcome.reviewVersionBefore,
      isNewCard: outcome.wasNewCard,
    );

    await offline.updateCardFromServer(
      'user-1',
      ReviewCard(
        id: 'card-1',
        deckId: 'deck-1',
        front: '单词',
        back: '释义',
        stage: 0,
        learningMode: false,
        consecutiveFamiliar: 0,
        learningStep: 0,
        reentryStage: null,
        nextReviewDate: null,
        reviewVersion: 0,
      ),
    );

    final localCard = await offline.getLocalCard('user-1', 'card-1');
    expect(localCard?.reviewVersion.toInt(), 1);
    expect(localCard?.stage, 1);
    expect(await offline.getPendingRatings('user-1'), hasLength(1));
  });
  test('overview and deck stats keep new learning separate from reviews', () async {
    await offline.saveBootstrap(
      userId: 'user-1',
      email: 'a@b.c',
      refreshTime: '04:00:00',
      serverTime: DateTime.utc(2025, 8, 10, 12),
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
              'stage': 0,
              'consecutive_familiar': 0,
              'next_review_date': null,
              'learning_mode': false,
              'reentry_stage': null,
              'learning_step': 0,
              'review_version': 0,
              'created_at': '2025-08-01T00:00:00Z',
              'updated_at': '2025-08-01T00:00:00Z',
            },
          ],
        },
      ],
      reviewLogs: [
        {
          'id': 'log-new',
          'card_id': 'card-1',
          'rating': 'FAMILIAR',
          'stage_before': 0,
          'stage_after': 1,
          'is_new_card': true,
          'reviewed_at': '2025-08-10T12:00:00Z',
        },
        {
          'id': 'log-review',
          'card_id': 'card-1',
          'rating': 'FAMILIAR',
          'stage_before': 2,
          'stage_after': 3,
          'is_new_card': false,
          'reviewed_at': '2025-08-10T13:00:00Z',
        },
      ],
    );

    final overview = await offline.getOverviewStats('user-1');
    expect(overview.reviewedToday, 1);
    expect(overview.learnedToday, 1);

    final deckStats = await offline.getDeckStats('user-1', 'deck-1');
    expect(deckStats.reviewedToday, 1);
  });

  test('trend maps logs to refresh days and excludes new learning from reviewed', () async {
    await offline.saveBootstrap(
      userId: 'user-1',
      email: 'a@b.c',
      refreshTime: '04:00:00',
      serverTime: DateTime.utc(2025, 8, 10, 12),
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
              'stage': 1,
              'consecutive_familiar': 0,
              'next_review_date': '2025-08-11',
              'learning_mode': false,
              'reentry_stage': null,
              'learning_step': 0,
              'review_version': 1,
              'created_at': '2025-08-01T00:00:00Z',
              'updated_at': '2025-08-10T12:00:00Z',
            },
          ],
        },
      ],
      reviewLogs: [
        {
          'id': 'log-new',
          'card_id': 'card-1',
          'rating': 'FAMILIAR',
          'stage_before': 0,
          'stage_after': 1,
          'is_new_card': true,
          'reviewed_at': '2025-08-10T12:00:00',
        },
        {
          'id': 'log-review',
          'card_id': 'card-1',
          'rating': 'FAMILIAR',
          'stage_before': 2,
          'stage_after': 3,
          'is_new_card': false,
          'reviewed_at': '2025-08-09T12:00:00',
        },
        {
          'id': 'log-before-refresh',
          'card_id': 'card-1',
          'rating': 'VAGUE',
          'stage_before': 3,
          'stage_after': 2,
          'is_new_card': false,
          'reviewed_at': '2025-08-10T03:00:00',
        },
      ],
    );

    final trend = await offline.getTrend('user-1', days: 5);

    expect(trend, hasLength(5));
    expect(trend.last.date, '2025-08-10');
    expect(trend.last.reviewed, 0);
    expect(trend.last.learned, 1);
    expect(trend[3].date, '2025-08-09');
    expect(trend[3].reviewed, 2);
    expect(trend[3].learned, 0);
  });

  test('sync bootstrap restores is_new_card into local stats', () async {
    final api = FakeApiClient();
    api.onGetProto = (path, query) async {
      expect(query, {'event_cursor': 0});
      return proto.SyncResponse(
        serverTime: '2025-08-10T12:00:00Z',
        user: proto.User(
          id: 'user-1',
          email: 'a@b.c',
          refreshTime: '04:00:00',
        ),
        decks: [
          proto.Deck(
            id: 'deck-1',
            name: '日语',
            createdAt: '2025-08-01T00:00:00Z',
            updatedAt: '2025-08-01T00:00:00Z',
            cards: [
              proto.Card(
                id: 'card-1',
                deckId: 'deck-1',
                front: '单词',
                back: '释义',
                stage: 1,
                learningMode: false,
                nextReviewDate: '2025-08-11',
                createdAt: '2025-08-01T00:00:00Z',
                updatedAt: '2025-08-10T12:00:00Z',
              ),
            ],
          ),
        ],
        reviewLogs: [
          proto.ReviewLog(
            id: 'log-new',
            cardId: 'card-1',
            rating: 'FAMILIAR',
            stageBefore: 0,
            stageAfter: 1,
            reviewedAt: '2025-08-10T12:00:00',
            isNewCard: true,
          ),
        ],
      ).writeToBuffer();
    };

    final sync = SyncService(SyncRepository(client: api), offline);
    await sync.bootstrap(userId: 'user-1');

    final stats = await offline.getOverviewStats('user-1');
    expect(stats.learnedToday, 1);
    expect(stats.reviewedToday, 0);
  });

  test('applyDelta upserts changed cards and deletes entities', () async {
    await offline.saveBootstrap(
      userId: 'user-1',
      email: 'a@b.c',
      refreshTime: '04:00:00',
      serverTime: DateTime.utc(2025, 8, 10, 12),
      decks: [
        {
          'id': 'deck-1',
          'name': '旧名',
          'created_at': '2025-08-01T00:00:00Z',
          'updated_at': '2025-08-01T00:00:00Z',
          'cards': [
            {
              'id': 'card-1',
              'deck_id': 'deck-1',
              'front': '旧正面',
              'back': '旧反面',
              'stage': 0,
              'consecutive_familiar': 0,
              'next_review_date': null,
              'learning_mode': false,
              'reentry_stage': null,
              'learning_step': 0,
              'review_version': 0,
              'created_at': '2025-08-01T00:00:00Z',
              'updated_at': '2025-08-01T00:00:00Z',
            },
          ],
        },
      ],
      reviewLogs: [],
      eventCursor: 1,
    );

    await offline.applyDelta(userId: 'user-1', data: {
      'decks': [],
      'changed_cards': [
        {
          'id': 'card-1',
          'deck_id': 'deck-1',
          'front': '新正面',
          'back': '新反面',
          'stage': 1,
          'consecutive_familiar': 0,
          'next_review_date': '2025-08-11',
          'learning_mode': false,
          'reentry_stage': null,
          'learning_step': 0,
          'review_version': 1,
          'created_at': '2025-08-01T00:00:00Z',
          'updated_at': '2025-08-10T12:00:00Z',
        },
      ],
      'review_logs': [],
      'deleted_deck_ids': ['deck-1'],
      'deleted_card_ids': [],
      'deleted_review_log_ids': [],
      'event_cursor': 2,
      'has_more': false,
      'reset_required': false,
    });

    expect(await offline.getDecks('user-1'), isEmpty);
    expect(await offline.getCards('user-1'), isEmpty);
    final meta = await offline.getSyncMeta('user-1');
    expect(meta?.lastEventCursor.toInt(), 2);
  });

  test('refresh shares one inflight delta request', () async {
    await offline.saveBootstrap(
      userId: 'user-1',
      email: 'a@b.c',
      refreshTime: '04:00:00',
      serverTime: DateTime.utc(2025, 8, 10, 12),
      decks: [],
      reviewLogs: [],
      eventCursor: 1,
    );
    var calls = 0;
    final api = FakeApiClient();
    api.onGetProto = (path, query) async {
      calls += 1;
      return proto.SyncResponse(
        serverTime: '2025-08-10T12:00:01Z',
        user: proto.User(
          id: 'user-1',
          email: 'a@b.c',
          refreshTime: '04:00:00',
        ),
        hasMore: false,
      ).writeToBuffer();
    };
    final sync = SyncService(SyncRepository(client: api), offline);
    await Future.wait([sync.refresh(), sync.refresh()]);
    expect(calls, 1);
  });

  test('no-zone reviewed_at is interpreted as Asia/Shanghai wall time', () async {
    await offline.saveBootstrap(
      userId: 'user-1',
      email: 'a@b.c',
      refreshTime: '04:00:00',
      serverTime: DateTime.utc(2025, 8, 10, 12),
      decks: [],
      reviewLogs: [
        {
          'id': 'log-before-refresh',
          'card_id': 'card-1',
          'rating': 'FAMILIAR',
          'stage_before': 2,
          'stage_after': 3,
          'is_new_card': false,
          'reviewed_at': '2025-08-10T03:00:00',
        },
      ],
    );

    final trend = await offline.getTrend('user-1', days: 2);
    expect(trend[0].date, '2025-08-09');
    expect(trend[0].reviewed, 1);
    expect(trend[1].date, '2025-08-10');
    expect(trend[1].reviewed, 0);
  });
}
