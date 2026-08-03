import 'package:flutter_test/flutter_test.dart';
import 'package:karisreview/auth/models/auth_config.dart';
import 'package:karisreview/auth/models/login_request.dart';
import 'package:karisreview/auth/models/login_response.dart';
import 'package:karisreview/auth/models/register_request.dart';
import 'package:karisreview/card/models/card.dart';
import 'package:karisreview/card/models/card_import.dart';
import 'package:karisreview/deck/models/deck.dart';
import 'package:karisreview/review/models/review_card.dart';
import 'package:karisreview/stats/models/stats.dart';

import 'helpers/test_helpers.dart';

void main() {
  group('Deck', () {
    test('parses backend snake_case fields and distributions', () {
      final deck = Deck.fromJson(deckJson());

      expect(deck.id, 'deck-1');
      expect(deck.name, '日语 N5');
      expect(deck.cardCount, 2);
      expect(deck.dueCount, 1);
      expect(deck.newCount, 1);
      expect(deck.stageDistribution[0], 1);
      expect(deck.stageDistribution[1], 1);
      expect(deck.dueStageDistribution[0], 1);
      expect(deck.stageDistribution.length, 9);
    });

    test('defaults missing fields', () {
      final deck = Deck.fromJson({'id': 'd', 'name': '空'});

      expect(deck.cardCount, 0);
      expect(deck.dueCount, 0);
      expect(deck.newCount, 0);
      expect(deck.stageDistribution, List.filled(9, 0));
    });
  });

  group('FlashCard', () {
    test('parses card response', () {
      final card = FlashCard.fromJson(cardJson(stage: 3));

      expect(card.id, 'card-1');
      expect(card.deckId, 'deck-1');
      expect(card.front, '正面');
      expect(card.stage, 3);
      expect(card.learningMode, isFalse);
    });

    test('defaults optional fields', () {
      final card = FlashCard.fromJson({'id': 'c', 'front': 'f', 'back': 'b'});

      expect(card.deckId, '');
      expect(card.stage, 0);
      expect(card.learningMode, isFalse);
      expect(card.consecutiveFamiliar, 0);
      expect(card.due, isFalse);
    });
  });

  group('Review models', () {
    test('parses review card', () {
      final card = ReviewCard.fromJson(reviewCardJson());

      expect(card.id, 'card-1');
      expect(card.learningGoal, 5);
      expect(card.familiarIntervalDays, 1);
    });

    test('parses rating result', () {
      final result = ReviewResult.fromJson(reviewResultJson());

      expect(result.rating, 'FAMILIAR');
      expect(result.stageBefore, 0);
      expect(result.stageAfter, 1);
      expect(result.nextIntervalDays, 1);
    });

    test('defaults missing review fields', () {
      final result = ReviewResult.fromJson({
        'card_id': 'c',
        'rating': 'FORGET',
      });

      expect(result.stageAfter, 0);
      expect(result.learningMode, isFalse);
      expect(result.nextIntervalDays, 0);
    });
  });

  group('Stats models', () {
    test('parses overview stats', () {
      final stats = OverviewStats.fromJson(overviewStatsJson());

      expect(stats.totalCards, 10);
      expect(stats.totalDecks, 2);
      expect(stats.dueToday, 3);
      expect(stats.reviewedToday, 4);
      expect(stats.learnedToday, 1);
      expect(stats.masteredCards, 2);
      expect(stats.stageDistribution[0], 8);
      expect(stats.dueStageDistribution[0], 3);
    });

    test('parses deck stats', () {
      final stats = DeckStats.fromJson(deckStatsJson());

      expect(stats.deckId, 'deck-1');
      expect(stats.deckName, '日语 N5');
      expect(stats.totalCards, 2);
      expect(stats.dueToday, 1);
    });

    test('parses trend point', () {
      final point = TrendPoint.fromJson(trendPointJson());

      expect(point.date, '2025-08-01');
      expect(point.reviewed, 3);
      expect(point.learned, 1);
    });

    test('stats distributions ignore out-of-range keys', () {
      final stats = OverviewStats.fromJson({
        'total_cards': 1,
        'total_decks': 1,
        'due_today': 0,
        'reviewed_today': 0,
        'learned_today': 0,
        'mastered_cards': 0,
        'learning_cards': 0,
        'stage_distribution': {'9': 1, '-1': 1, '2': 4},
      });

      expect(stats.stageDistribution[2], 4);
      expect(stats.stageDistribution[8], 0);
    });
  });

  group('Import preview', () {
    test('parses preview response rows', () {
      final data = importPreviewJson();
      final items = (data['cards'] as List<dynamic>)
          .map(
            (item) =>
                CardImportPreviewItem.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      expect(items[0].valid, isTrue);
      expect(items[1].message, '正面内容不能为空');
      expect(items[1].front, '');
    });

    test('parses import result with card ids', () {
      final result = CardImportResult.fromJson(importResultJson());

      expect(result.importedCards, 2);
      expect(result.importedCardIds, ['card-1', 'card-2']);
    });

    test('copyWith clears message', () {
      const item = CardImportPreviewItem(
        index: 0,
        front: '',
        back: '',
        valid: false,
        message: '错误',
      );

      final updated = item.copyWith(
        front: 'f',
        back: 'b',
        valid: true,
        clearMessage: true,
      );

      expect(updated.valid, isTrue);
      expect(updated.message, isNull);
    });
  });

  group('Auth models', () {
    test('parses login response', () {
      final response = LoginResponse.fromJson({
        'token': 'token',
        'user': {'id': 'u1', 'email': 'user@example.com'},
      });

      expect(response.token, 'token');
      expect(response.user.id, 'u1');
      expect(response.user.email, 'user@example.com');
    });
    test('serializes login request', () {
      final request = LoginRequest(email: 'a@b.c', password: 'secret');

      expect(request.toJson(), {'email': 'a@b.c', 'password': 'secret'});
    });

    test('parses auth config with default', () {
      expect(
        AuthConfig.fromJson({'invite_code_required': true}).inviteCodeRequired,
        isTrue,
      );
      expect(AuthConfig.fromJson({}).inviteCodeRequired, isFalse);
    });

    test('serializes register request with invite code', () {
      final request = RegisterRequest(
        email: 'a@b.c',
        password: 'secret',
        inviteCode: 'invite-1',
      );

      expect(request.toJson(), {
        'email': 'a@b.c',
        'password': 'secret',
        'invite_code': 'invite-1',
      });
    });

    test('omits empty register invite code', () {
      final request = RegisterRequest(
        email: 'a@b.c',
        password: 'secret',
        inviteCode: '',
      );

      expect(request.toJson(), {'email': 'a@b.c', 'password': 'secret'});
    });
  });
}
