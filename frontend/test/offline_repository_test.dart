import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karisreview/card/models/card.dart';
import 'package:karisreview/offline/database/app_database.dart';
import 'package:karisreview/offline/local_scheduling_engine.dart';
import 'package:karisreview/offline/offline_repository.dart';

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
    );

    final pending = await offline.getPendingRatings('user-1');
    expect(pending, hasLength(1));
    expect(pending.single.reviewVersion.toInt(), 0);

    final localCard = await offline.getLocalCard('user-1', 'card-1');
    expect(localCard?.reviewVersion.toInt(), 1);
    expect(localCard?.stage, 1);
  });
}
