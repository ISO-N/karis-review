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
    String? nextReviewDate,
    int version = 0,
  }) {
    return FlashCard(
      id: 'card-1',
      deckId: 'deck-1',
      front: '正面',
      back: '反面',
      stage: stage,
      nextReviewDate: nextReviewDate,
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

  test('familiar at max stage stays at stage eight with 180 days', () {
    final outcome = engine.rate(
      card(stage: 8, version: 4),
      'FAMILIAR',
      nowUtc: now,
      refreshTime: '04:00:00',
    );

    expect(outcome.card.stage, 8);
    expect(
      DateTime.parse(outcome.card.nextReviewDate!).difference(
        DateTime(2025, 8, 2),
      ).inDays,
      180,
    );
    expect(outcome.card.reviewVersion, 5);
  });

  test('vague on stage zero and one behaves like forget', () {
    final stageZero = engine.rate(
      card(stage: 0),
      'VAGUE',
      nowUtc: now,
      refreshTime: '04:00:00',
    );
    final stageOne = engine.rate(
      card(stage: 1),
      'VAGUE',
      nowUtc: now,
      refreshTime: '04:00:00',
    );

    expect(stageZero.card.stage, 0);
    expect(stageZero.card.learningMode, isTrue);
    expect(stageOne.card.stage, 0);
    expect(stageOne.card.learningMode, isTrue);
    expect(stageOne.card.reentryStage, isNull);
  });

  test('forget resets relearning familiar counter without extra downgrade', () {
    final current = engine
        .rate(
          card(stage: 5, learning: true, consecutive: 2, reentry: 5),
          'FAMILIAR',
          nowUtc: now,
          refreshTime: '04:00:00',
        )
        .card;

    final reset = engine.rate(
      current,
      'FORGET',
      nowUtc: now,
      refreshTime: '04:00:00',
    );

    expect(reset.card.stage, 0);
    expect(reset.card.consecutiveFamiliar, 0);
    expect(reset.card.learningMode, isTrue);
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

  test('effective stage maps overdue ratio to lower stage', () {
    expect(LocalSchedulingEngine.calculateEffectiveStage(4, 0), 4);
    expect(LocalSchedulingEngine.calculateEffectiveStage(4, 3), 4);
    expect(LocalSchedulingEngine.calculateEffectiveStage(4, 7), 3);
    expect(LocalSchedulingEngine.calculateEffectiveStage(4, 20), 3);
    expect(LocalSchedulingEngine.calculateEffectiveStage(4, 82), 1);
    expect(LocalSchedulingEngine.calculateEffectiveStage(8, 60), 8);
    expect(LocalSchedulingEngine.calculateEffectiveStage(8, 200), 7);
    expect(LocalSchedulingEngine.calculateEffectiveStage(8, 1825), greaterThanOrEqualTo(3));
  });

  test('effective stage applies grace rules', () {
    expect(LocalSchedulingEngine.calculateEffectiveStage(4, 2), 4);
    expect(LocalSchedulingEngine.calculateEffectiveStage(3, 2), 3);
    expect(LocalSchedulingEngine.calculateEffectiveStage(1, 30), 1);
    expect(LocalSchedulingEngine.calculateEffectiveStage(0, 30), 0);
  });

  test('vague on overdue card steps back from effective stage', () {
    final outcome = engine.rate(
      card(stage: 4, nextReviewDate: '2025-07-26'),
      'VAGUE',
      nowUtc: now,
      refreshTime: '04:00:00',
    );

    expect(outcome.card.stage, 2);
    expect(outcome.card.reentryStage, 3);
    expect(outcome.card.learningMode, isTrue);
  });

  test('vague overdue relearning returns to effective stage', () {
    var current = engine
        .rate(
          card(stage: 4, nextReviewDate: '2025-07-26'),
          'VAGUE',
          nowUtc: now,
          refreshTime: '04:00:00',
        )
        .card;

    for (var i = 0; i < 2; i++) {
      current = engine
          .rate(current, 'FAMILIAR', nowUtc: now, refreshTime: '04:00:00')
          .card;
    }
    final completed = engine.rate(
      current,
      'FAMILIAR',
      nowUtc: now,
      refreshTime: '04:00:00',
    );

    expect(completed.card.learningMode, isFalse);
    expect(completed.card.stage, 3);
    expect(completed.card.nextReviewDate, '2025-08-04');
  });

  test('vague on heavily overdue card degrades to forget', () {
    final outcome = engine.rate(
      card(stage: 2, nextReviewDate: '2025-07-03'),
      'VAGUE',
      nowUtc: now,
      refreshTime: '04:00:00',
    );

    expect(outcome.card.stage, 0);
    expect(outcome.card.learningMode, isTrue);
    expect(outcome.card.reentryStage, isNull);
  });

  test('vague within grace period does not downgrade extra', () {
    final outcome = engine.rate(
      card(stage: 4, nextReviewDate: '2025-07-31'),
      'VAGUE',
      nowUtc: now,
      refreshTime: '04:00:00',
    );

    expect(outcome.card.stage, 3);
    expect(outcome.card.reentryStage, 4);
  });
}
