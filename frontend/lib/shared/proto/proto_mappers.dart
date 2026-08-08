import 'package:protobuf/protobuf.dart' as $pb;

import 'karis_review.pb.dart';

// 声明式字段映射（架构评审候选 1，2026-08）。
//
// 键集合单一数据源：由 protobuf 生成代码的 BuilderInfo（info_.byIndex）推导——
// 每新增 proto 字段自动进入映射，无需手写键清单，杜绝手写字面量键漏映射。
// 值获取必须显式书写（Dart Web 无运行时反射）；值函数未处理的字段会抛
// UnsupportedError，字段对账测试（test/proto_mappers_test.dart）立刻红，
// 防止 learning_origin 类漏映射生产故障复发。
// 目标键为 snake_case：与 Drift 列名 / 后端 JSON 通道一致。

/// camelCase → snake_case（proto dart 字段名 → 映射键）。
String camelToSnake(String name) {
  final buf = StringBuffer();
  for (var i = 0; i < name.length; i++) {
    final ch = name[i];
    if (ch.toUpperCase() == ch && ch.toLowerCase() != ch) {
      if (i > 0) buf.write('_');
      buf.write(ch.toLowerCase());
    } else {
      buf.write(ch);
    }
  }
  return buf.toString();
}

/// 通用投影器：遍历生成代码注册的全部字段，键 = snake_case(字段名)，值 = valueOf。
///
/// 值函数对未知字段抛 [UnsupportedError]——漏映射在测试期暴露。
Map<String, dynamic> _project<T extends $pb.GeneratedMessage>(
  T msg,
  dynamic Function(T msg, String field) valueOf,
) {
  final map = <String, dynamic>{};
  for (final info in msg.info_.byIndex) {
    map[camelToSnake(info.name)] = valueOf(msg, info.name);
  }
  return map;
}

// ---------------------------------------------------------------- 值函数

dynamic _userValue(User msg, String f) => switch (f) {
      'id' => msg.id,
      'email' => msg.email,
      'refreshTime' => msg.refreshTime,
      _ => throw UnsupportedError('User 字段未映射: $f'),
    };

dynamic _cardValue(Card msg, String f) => switch (f) {
      'id' => msg.id,
      'deckId' => msg.deckId,
      'front' => msg.front,
      'back' => msg.back,
      'stage' => msg.stage,
      'consecutiveFamiliar' => msg.consecutiveFamiliar,
      'nextReviewDate' => msg.hasNextReviewDate() ? msg.nextReviewDate : null,
      'learningMode' => msg.learningMode,
      'reentryStage' => msg.hasReentryStage() ? msg.reentryStage : null,
      'learningStep' => msg.learningStep,
      'reviewVersion' => msg.reviewVersion.toInt(),
      'createdAt' => msg.createdAt,
      'updatedAt' => msg.updatedAt,
      'learningOrigin' => msg.hasLearningOrigin() ? msg.learningOrigin : null,
      _ => throw UnsupportedError('Card 字段未映射: $f'),
    };

dynamic _deckValue(Deck msg, String f) => switch (f) {
      'id' => msg.id,
      'name' => msg.name,
      'createdAt' => msg.createdAt,
      'updatedAt' => msg.updatedAt,
      'cards' => msg.cards.map(cardToMap).toList(),
      _ => throw UnsupportedError('Deck 字段未映射: $f'),
    };

dynamic _reviewLogValue(ReviewLog msg, String f) => switch (f) {
      'id' => msg.id,
      'cardId' => msg.cardId,
      'rating' => msg.rating,
      'stageBefore' => msg.stageBefore,
      'stageAfter' => msg.stageAfter,
      'reviewedAt' => msg.reviewedAt,
      'isNewCard' => msg.isNewCard,
      'clientRequestId' =>
        msg.hasClientRequestId() ? msg.clientRequestId : null,
      'learningOrigin' => msg.hasLearningOrigin() ? msg.learningOrigin : null,
      _ => throw UnsupportedError('ReviewLog 字段未映射: $f'),
    };

dynamic _reviewCardValue(ReviewCard msg, String f) => switch (f) {
      'id' => msg.id,
      'deckId' => msg.deckId,
      'front' => msg.front,
      'back' => msg.back,
      'stage' => msg.stage,
      'learningMode' => msg.learningMode,
      'consecutiveFamiliar' => msg.consecutiveFamiliar,
      'learningStep' => msg.learningStep,
      'reentryStage' => msg.hasReentryStage() ? msg.reentryStage : null,
      'nextReviewDate' => msg.hasNextReviewDate() ? msg.nextReviewDate : null,
      'reviewVersion' => msg.reviewVersion.toInt(),
      'learningOrigin' => msg.hasLearningOrigin() ? msg.learningOrigin : null,
      _ => throw UnsupportedError('ReviewCard 字段未映射: $f'),
    };

dynamic _reviewCardListValue(ReviewCardListResponse msg, String f) =>
    switch (f) {
      'cards' => msg.cards.map(reviewCardToMap).toList(),
      _ => throw UnsupportedError('ReviewCardListResponse 字段未映射: $f'),
    };

dynamic _sessionPageValue(ReviewSessionPageResponse msg, String f) =>
    switch (f) {
      'sessionId' => msg.sessionId,
      'mode' => msg.mode,
      'deckId' => msg.hasDeckId() ? msg.deckId : null,
      'batchSize' => msg.batchSize,
      'total' => msg.total,
      'cursor' => msg.cursor,
      'hasMore' => msg.hasMore,
      'cards' => msg.cards.map(reviewCardToMap).toList(),
      _ => throw UnsupportedError('ReviewSessionPageResponse 字段未映射: $f'),
    };

dynamic _syncItemResultValue(ReviewSyncItemResult msg, String f) => switch (f) {
      'clientRequestId' => msg.clientRequestId,
      'status' => msg.status,
      'currentCard' => msg.hasCurrentCard() ? reviewCardToMap(msg.currentCard) : null,
      'cardId' => msg.cardId,
      _ => throw UnsupportedError('ReviewSyncItemResult 字段未映射: $f'),
    };

dynamic _syncResponseValue(SyncResponse msg, String f) => switch (f) {
      'serverTime' => msg.serverTime,
      'user' => userToMap(msg.user),
      'decks' => msg.decks.map(deckToMap).toList(),
      'reviewLogs' => msg.reviewLogs.map(reviewLogToMap).toList(),
      'changedCards' => msg.changedCards.map(cardToMap).toList(),
      'deletedDeckIds' => msg.deletedDeckIds.toList(),
      'deletedCardIds' => msg.deletedCardIds.toList(),
      'deletedReviewLogIds' => msg.deletedReviewLogIds.toList(),
      'eventCursor' => msg.eventCursor.toInt(),
      'hasMore' => msg.hasMore,
      'resetRequired' => msg.resetRequired,
      _ => throw UnsupportedError('SyncResponse 字段未映射: $f'),
    };

dynamic _reviewSyncResponseValue(ReviewSyncResponse msg, String f) =>
    switch (f) {
      'synced' => msg.synced,
      'conflicts' => msg.conflicts,
      'missing' => msg.missing,
      'items' => msg.items.map(reviewSyncItemResultToMap).toList(),
      _ => throw UnsupportedError('ReviewSyncResponse 字段未映射: $f'),
    };

// ------------------------------------------------------------ 公开映射函数

Map<String, dynamic> syncResponseToMap(SyncResponse proto) =>
    _project(proto, _syncResponseValue);

Map<String, dynamic> userToMap(User user) => _project(user, _userValue);

Map<String, dynamic> deckToMap(Deck deck) => _project(deck, _deckValue);

Map<String, dynamic> cardToMap(Card card) => _project(card, _cardValue);

Map<String, dynamic> reviewLogToMap(ReviewLog log) =>
    _project(log, _reviewLogValue);

Map<String, dynamic> reviewCardToMap(ReviewCard card) =>
    _project(card, _reviewCardValue);

List<Map<String, dynamic>> reviewCardListToMaps(ReviewCardListResponse proto) =>
    _project(proto, _reviewCardListValue)['cards'] as List<Map<String, dynamic>>;

Map<String, dynamic> reviewSessionPageToMap(ReviewSessionPageResponse proto) =>
    _project(proto, _sessionPageValue);

Map<String, dynamic> reviewSyncResponseToMap(ReviewSyncResponse proto) =>
    _project(proto, _reviewSyncResponseValue);

Map<String, dynamic> reviewSyncItemResultToMap(ReviewSyncItemResult item) =>
    _project(item, _syncItemResultValue);
