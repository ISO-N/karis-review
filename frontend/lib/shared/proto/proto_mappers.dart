import 'karis_review.pb.dart';

Map<String, dynamic> syncResponseToMap(SyncResponse proto) {
  return {
    'server_time': proto.serverTime,
    'user': {
      'id': proto.user.id,
      'email': proto.user.email,
      'refresh_time': proto.user.refreshTime,
    },
    'decks': proto.decks.map(deckToMap).toList(),
    'review_logs': proto.reviewLogs.map(reviewLogToMap).toList(),
    'changed_cards': proto.changedCards.map(cardToMap).toList(),
    'deleted_deck_ids': proto.deletedDeckIds.toList(),
    'deleted_card_ids': proto.deletedCardIds.toList(),
    'deleted_review_log_ids': proto.deletedReviewLogIds.toList(),
    'event_cursor': proto.eventCursor.toInt(),
    'has_more': proto.hasMore,
    'reset_required': proto.resetRequired,
  };
}

Map<String, dynamic> deckToMap(Deck deck) {
  return {
    'id': deck.id,
    'name': deck.name,
    'created_at': deck.createdAt,
    'updated_at': deck.updatedAt,
    'cards': deck.cards.map(cardToMap).toList(),
  };
}

Map<String, dynamic> cardToMap(Card card) {
  return {
    'id': card.id,
    'deck_id': card.deckId,
    'front': card.front,
    'back': card.back,
    'stage': card.stage,
    'consecutive_familiar': card.consecutiveFamiliar,
    'next_review_date': card.hasNextReviewDate() ? card.nextReviewDate : null,
    'learning_mode': card.learningMode,
    'reentry_stage': card.hasReentryStage() ? card.reentryStage : null,
    'learning_step': card.learningStep,
    'review_version': card.reviewVersion.toInt(),
    'created_at': card.createdAt,
    'updated_at': card.updatedAt,
  };
}

Map<String, dynamic> reviewLogToMap(ReviewLog log) {
  return {
    'id': log.id,
    'card_id': log.cardId,
    'rating': log.rating,
    'stage_before': log.stageBefore,
    'stage_after': log.stageAfter,
    'reviewed_at': log.reviewedAt,
    'is_new_card': log.isNewCard,
  };
}

Map<String, dynamic> reviewCardToMap(ReviewCard card) {
  return {
    'id': card.id,
    'deck_id': card.deckId,
    'front': card.front,
    'back': card.back,
    'stage': card.stage,
    'learning_mode': card.learningMode,
    'consecutive_familiar': card.consecutiveFamiliar,
    'learning_step': card.learningStep,
    'reentry_stage': card.hasReentryStage() ? card.reentryStage : null,
    'next_review_date': card.hasNextReviewDate() ? card.nextReviewDate : null,
    'review_version': card.reviewVersion.toInt(),
  };
}

List<Map<String, dynamic>> reviewCardListToMaps(ReviewCardListResponse proto) {
  return proto.cards.map(reviewCardToMap).toList();
}

Map<String, dynamic> reviewSessionPageToMap(ReviewSessionPageResponse proto) {
  return {
    'session_id': proto.sessionId,
    'mode': proto.mode,
    'deck_id': proto.hasDeckId() ? proto.deckId : null,
    'batch_size': proto.batchSize,
    'total': proto.total,
    'cursor': proto.cursor,
    'has_more': proto.hasMore,
    'cards': proto.cards.map(reviewCardToMap).toList(),
  };
}

Map<String, dynamic> reviewSyncResponseToMap(ReviewSyncResponse proto) {
  return {
    'synced': proto.synced,
    'conflicts': proto.conflicts,
    'missing': proto.missing,
    'items': proto.items.map((item) {
      return {
        'client_request_id': item.clientRequestId,
        'status': item.status,
        'current_card': item.hasCurrentCard()
            ? reviewCardToMap(item.currentCard)
            : null,
      };
    }).toList(),
  };
}
