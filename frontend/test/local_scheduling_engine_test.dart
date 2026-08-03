import 'package:flutter_test/flutter_test.dart';
import 'package:karisreview/card/models/card.dart';
import 'package:karisreview/offline/local_scheduling_engine.dart';

void main() {
  final engine = LocalSchedulingEngine();
  final now = DateTime.utc(2025, 8, 2, 12);

  FlashCard card({
    int stage = 0,
    bool learning = false,
    int consecutive = 0,
    int step = 0,
    int? reentry,
    int version = 0,
  }) {
    return FlashCard(
      id: 'card-1',
      deckId: 'deck-1',
      front: '正面',
      back: '反面',
      stage: stage,
      learningMode: learning,
      consecutiveFamiliar: consecutive,
      learningStep: step,
      reentryStage: reentry,
      reviewVersion: version,
    );
  }

  test('familiar on new card moves to stage one and increments version', () {
    final outcome = engine.rate(
      card(),
      'FAMILIAR',
      nowUtc: now,
      refreshTime: '04:00:00',
    );

    expect(outcome.card.stage, 1);
    expect(outcome.card.nextReviewDate, '2025-08-03');
    expect(outcome.card.reviewVersion, 1);
    expect(outcome.reviewVersionBefore, 0);
    expect(outcome.wasNewCard, isTrue);
  });

  test('forget enters relearning mode and resets state', () {
    final outcome = engine.rate(
      card(stage: 4, version: 3),
      'FORGET',
      nowUtc: now,
      refreshTime: '04:00:00',
    );

    expect(outcome.card.stage, 0);
    expect(outcome.card.learningMode, isTrue);
    expect(outcome.card.consecutiveFamiliar, 0);
    expect(outcome.card.learningStep, 0);
    expect(outcome.card.nextReviewDate, '2025-08-02');
    expect(outcome.card.reviewVersion, 4);
  });

  test('vague steps back and requires three familiar ratings', () {
    final vague = engine.rate(
      card(stage: 4, version: 5),
      'VAGUE',
      nowUtc: now,
      refreshTime: '04:00:00',
    );

    expect(vague.card.stage, 3);
    expect(vague.card.reentryStage, 4);
    expect(vague.card.learningMode, isTrue);

    var current = vague.card;
    for (var i = 0; i < 2; i++) {
      final next = engine.rate(
        current,
        'FAMILIAR',
        nowUtc: now,
        refreshTime: '04:00:00',
      );
      current = next.card;
      expect(current.learningMode, isTrue);
    }
    final completed = engine.rate(
      current,
      'FAMILIAR',
      nowUtc: now,
      refreshTime: '04:00:00',
    );
    expect(completed.card.learningMode, isFalse);
    expect(completed.card.stage, 4);
    expect(completed.card.nextReviewDate, '2025-08-05');
  });

  test('forget relearning requires five familiar ratings', () {
    var current = engine
        .rate(card(stage: 6), 'FORGET', nowUtc: now, refreshTime: '04:00:00')
        .card;
    for (var i = 0; i < 4; i++) {
      final next = engine.rate(
        current,
        'FAMILIAR',
        nowUtc: now,
        refreshTime: '04:00:00',
      );
      current = next.card;
      expect(current.learningMode, isTrue);
      expect(current.consecutiveFamiliar, i + 1);
    }
    final completed = engine.rate(
      current,
      'FAMILIAR',
      nowUtc: now,
      refreshTime: '04:00:00',
    );
    expect(completed.card.learningMode, isFalse);
    expect(completed.card.stage, 1);
  });

  test('calculateToday uses Asia/Shanghai instead of device local time', () {
    expect(
      LocalSchedulingEngine.calculateToday(
        DateTime.utc(2025, 8, 1, 19),
        '04:00:00',
      ),
      DateTime(2025, 8, 1),
    );
    expect(
      LocalSchedulingEngine.calculateToday(
        DateTime.utc(2025, 8, 1, 20),
        '04:00:00',
      ),
      DateTime(2025, 8, 2),
    );
  });
}
