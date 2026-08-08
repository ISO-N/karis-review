import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protobuf/protobuf.dart' as $pb;

import 'package:karisreview/shared/proto/karis_review.pb.dart' as proto;
import 'package:karisreview/shared/proto/proto_mappers.dart';

/// 字段对账：映射键集合必须恰好等于生成代码注册的全部 proto 字段（snake_case）。
///
/// 声明式投影器无条件遍历 `info_.byIndex`，值函数对未处理字段抛
/// UnsupportedError——因此"加 proto 字段而忘映射"会在任何用例上直接红，
/// 从机制上杜绝 learning_origin 类漏映射生产故障（architecture.md §7.1.2）复发。
void expectFieldCoverage<T extends $pb.GeneratedMessage>(
  T msg,
  Map<String, dynamic> Function(T) mapFn, {
  required String label,
}) {
  final map = mapFn(msg);
  final expected = msg.info_.byIndex
      .map((f) => camelToSnake(f.name))
      .toSet();
  expect(
    map.keys.toSet(),
    expected,
    reason: '$label 映射键集合必须与生成代码字段一一对应'
        '（若值函数漏字段会先抛 UnsupportedError）',
  );
}

void main() {
  final card = proto.Card(
    id: 'card-1',
    deckId: 'deck-1',
    front: 'front',
    back: 'back',
    stage: 3,
    consecutiveFamiliar: 2,
    nextReviewDate: '2026-08-09',
    learningMode: true,
    reentryStage: '1',
    learningStep: 2,
    reviewVersion: Int64(7),
    createdAt: '2026-08-01T00:00:00',
    updatedAt: '2026-08-08T00:00:00',
    learningOrigin: 'NEW',
  );
  final reviewCard = proto.ReviewCard(
    id: 'card-1',
    deckId: 'deck-1',
    front: 'front',
    back: 'back',
    stage: 3,
    learningMode: true,
    consecutiveFamiliar: 2,
    learningStep: 2,
    reentryStage: '1',
    nextReviewDate: '2026-08-09',
    reviewVersion: Int64(7),
    learningOrigin: 'REVIEW',
  );

  group('cardToMap', () {
    test('字段对账 + 关键值', () {
      expectFieldCoverage(card, cardToMap, label: 'cardToMap');
      final map = cardToMap(card);
      expect(map['id'], 'card-1');
      expect(map['deck_id'], 'deck-1');
      expect(map['learning_origin'], 'NEW');
      expect(map['learning_step'], 2);
      expect(map['review_version'], 7); // int64 → int
      expect(map['next_review_date'], '2026-08-09');
    });

    test('optional 未设置映射为 null', () {
      final map = cardToMap(proto.Card(id: 'c', deckId: 'd'));
      expect(map['learning_origin'], isNull);
      expect(map['next_review_date'], isNull);
      expect(map['reentry_stage'], isNull);
    });
  });

  group('reviewLogToMap', () {
    test('保留 learning_origin（回归：曾漏映射导致本地统计误计学新重学）', () {
      final map = reviewLogToMap(
        proto.ReviewLog(
          id: 'log-1',
          cardId: 'card-1',
          rating: 'FAMILIAR',
          stageBefore: 0,
          stageAfter: 0,
          reviewedAt: '2026-08-08T10:00:00',
          isNewCard: false,
          learningOrigin: 'NEW',
          clientRequestId: 'req-1',
        ),
      );

      expectFieldCoverage(
        proto.ReviewLog(
          id: 'log-1',
          cardId: 'card-1',
          rating: 'FAMILIAR',
          stageBefore: 0,
          stageAfter: 0,
          reviewedAt: '2026-08-08T10:00:00',
          isNewCard: false,
          learningOrigin: 'NEW',
          clientRequestId: 'req-1',
        ),
        reviewLogToMap,
        label: 'reviewLogToMap',
      );
      expect(map['learning_origin'], 'NEW');
      expect(map['is_new_card'], false);
      expect(map['client_request_id'], 'req-1');
    });

    test('learning_origin 为空时映射为 null', () {
      final map = reviewLogToMap(
        proto.ReviewLog(
          id: 'log-2',
          cardId: 'card-2',
          rating: 'FAMILIAR',
          stageBefore: 1,
          stageAfter: 2,
          reviewedAt: '2026-08-08T10:00:00',
          isNewCard: false,
        ),
      );

      expect(map['learning_origin'], isNull);
    });
  });

  group('userToMap', () {
    test('字段对账 + 键形态', () {
      final msg = proto.User(id: 'u1', email: 'a@b.c', refreshTime: '04:00:00');
      expectFieldCoverage(msg, userToMap, label: 'userToMap');
      expect(userToMap(msg)['refresh_time'], '04:00:00');
    });
  });

  group('deckToMap', () {
    test('字段对账 + 嵌套卡片递归', () {
      final msg = proto.Deck(
        id: 'd1',
        name: 'deck',
        createdAt: 't1',
        updatedAt: 't2',
        cards: [card],
      );
      expectFieldCoverage(msg, deckToMap, label: 'deckToMap');
      final map = deckToMap(msg);
      expect(map['cards'], isA<List<dynamic>>());
      expect((map['cards'] as List).single['learning_origin'], 'NEW');
    });
  });

  group('reviewCardToMap', () {
    test('字段对账 + 关键值', () {
      expectFieldCoverage(reviewCard, reviewCardToMap, label: 'reviewCardToMap');
      final map = reviewCardToMap(reviewCard);
      expect(map['learning_origin'], 'REVIEW');
      expect(map['review_version'], 7);
    });
  });

  group('reviewCardListToMaps', () {
    test('列表展开 + 单卡字段对账（漏字段会在值函数抛 UnsupportedError）', () {
      final msg = proto.ReviewCardListResponse(cards: [reviewCard]);
      final list = reviewCardListToMaps(msg);
      expect(list, hasLength(1));
      expect(list.single['learning_origin'], 'REVIEW');
      expect(list.single['review_version'], 7);
      expectFieldCoverage(reviewCard, reviewCardToMap,
          label: 'reviewCardToMap（列表通道复用同一投影）');
    });
  });

  group('reviewSessionPageToMap', () {
    test('字段对账 + 关键值', () {
      final msg = proto.ReviewSessionPageResponse(
        sessionId: 's1',
        mode: 'due',
        deckId: 'd1',
        batchSize: 10,
        total: 42,
        cursor: 1,
        hasMore: true,
        cards: [reviewCard],
      );
      expectFieldCoverage(msg, reviewSessionPageToMap,
          label: 'reviewSessionPageToMap');
      final map = reviewSessionPageToMap(msg);
      expect(map['deck_id'], 'd1');
      expect(map['has_more'], true);
      expect(map['total'], 42);
      expect((map['cards'] as List).single['review_version'], 7);
    });

    test('optional deck_id 未设置映射为 null', () {
      final map = reviewSessionPageToMap(proto.ReviewSessionPageResponse(
        sessionId: 's1',
        mode: 'due',
        batchSize: 10,
        total: 0,
        cursor: 0,
        hasMore: false,
      ));
      expect(map['deck_id'], isNull);
    });
  });

  group('reviewSyncResponseToMap / reviewSyncItemResultToMap', () {
    test('字段对账 + 覆盖全部 items 字段（回归：内联映射曾漏 card_id）', () {
      final item = proto.ReviewSyncItemResult(
        clientRequestId: 'req-1',
        status: 'CONFLICT',
        currentCard: reviewCard,
        cardId: 'card-1',
      );
      expectFieldCoverage(item, reviewSyncItemResultToMap,
          label: 'reviewSyncItemResultToMap');
      final msg = proto.ReviewSyncResponse(
        synced: 0,
        conflicts: 1,
        missing: 0,
        items: [item],
      );
      expectFieldCoverage(msg, reviewSyncResponseToMap,
          label: 'reviewSyncResponseToMap');
      final map = reviewSyncResponseToMap(msg);
      final itemMap = (map['items'] as List).single as Map<String, dynamic>;
      expect(itemMap['client_request_id'], 'req-1');
      expect(itemMap['status'], 'CONFLICT');
      expect(itemMap['card_id'], 'card-1'); // 声明式投影自动补上
      expect((itemMap['current_card'] as Map)['review_version'], 7);
    });
  });

  group('syncResponseToMap', () {
    test('字段对账 + 全通道展开', () {
      final msg = proto.SyncResponse(
        serverTime: '2026-08-08T00:00:00Z',
        user: proto.User(id: 'u1', email: 'a@b.c', refreshTime: '04:00:00'),
        decks: [proto.Deck(id: 'd1', name: 'n', createdAt: 't', updatedAt: 't', cards: [card])],
        reviewLogs: [
          proto.ReviewLog(
            id: 'l1',
            cardId: 'card-1',
            rating: 'FAMILIAR',
            stageBefore: 0,
            stageAfter: 1,
            reviewedAt: '2026-08-08T10:00:00',
            isNewCard: false,
          ),
        ],
        changedCards: [card],
        deletedDeckIds: ['dd1'],
        deletedCardIds: ['dc1'],
        deletedReviewLogIds: ['dl1'],
        eventCursor: Int64(128),
        hasMore: true,
        resetRequired: false,
      );
      expectFieldCoverage(msg, syncResponseToMap, label: 'syncResponseToMap');
      final map = syncResponseToMap(msg);
      expect(map['event_cursor'], 128);
      expect(map['reset_required'], false);
      expect((map['review_logs'] as List).single['learning_origin'], isNull);
      expect((map['changed_cards'] as List).single['learning_origin'], 'NEW');
      expect((map['user'] as Map)['refresh_time'], '04:00:00');
    });
  });

  group('camelToSnake', () {
    test('驼峰转下划线', () {
      expect(camelToSnake('deckId'), 'deck_id');
      expect(camelToSnake('refreshTime'), 'refresh_time');
      expect(camelToSnake('serverTime'), 'server_time');
      expect(camelToSnake('eventCursor'), 'event_cursor');
      expect(camelToSnake('id'), 'id');
      expect(camelToSnake('hasMore'), 'has_more');
    });
  });
}
