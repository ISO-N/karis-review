import 'package:drift/drift.dart';

import '../../card/models/card.dart';
import '../../deck/models/deck.dart';
import '../../review/models/review_card.dart';
import '../../shared/utils/app_timezone.dart';
import '../../stats/models/stats.dart';
import 'database/app_database.dart';
import 'local_scheduling_engine.dart';

class OfflineRepository {
  final AppDatabase db;

  OfflineRepository(this.db);

  Stream<List<LocalDeck>> watchDecks(String userId) {
    return (db.select(db.localDecks)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Stream<List<LocalCard>> watchCards(String userId, {String? deckId}) {
    final query = db.select(db.localCards)
      ..where((t) => t.userId.equals(userId));
    if (deckId != null) {
      query.where((t) => t.deckId.equals(deckId));
    }
    return query.watch();
  }

  Future<List<LocalDeck>> getDecks(String userId) async {
    final rows =
        await (db.select(db.localDecks)
              ..where((t) => t.userId.equals(userId))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    return rows;
  }

  Future<List<LocalCard>> getCards(String userId, {String? deckId}) async {
    final query = db.select(db.localCards)
      ..where((t) => t.userId.equals(userId));
    if (deckId != null) {
      query.where((t) => t.deckId.equals(deckId));
    }
    return query.get();
  }

  Future<List<FlashCard>> getFlashCards(String userId, {String? deckId}) async {
    final cards = await getCards(userId, deckId: deckId);
    return cards.map(_toFlashCard).toList();
  }

  Future<List<FlashCard>> getFilteredFlashCards(
    String userId, {
    String? deckId,
    String filter = 'all',
    String query = '',
  }) async {
    final cards = await getCards(userId, deckId: deckId);
    final meta = await getSyncMeta(userId);
    final today = _formatDate(_today(meta));
    final normalizedQuery = query.trim().toLowerCase();
    final filtered =
        switch (filter) {
          'due' => cards.where(
            (c) =>
                c.nextReviewDate != null &&
                c.nextReviewDate!.compareTo(today) <= 0,
          ),
          'learning' => cards.where((c) => c.learningMode),
          'new' =>
            cards.where((c) => c.stage == 0 && !c.learningMode).toList()..sort(
              (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                  .compareTo(
                    a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
                  ),
            ),
          _ => cards.where((_) => true),
        }.where(
          (card) =>
              normalizedQuery.isEmpty ||
              card.front.toLowerCase().contains(normalizedQuery) ||
              card.back.toLowerCase().contains(normalizedQuery),
        );
    return filtered.map(_toFlashCard).toList();
  }

  Future<List<ReviewCard>> getDueQueue(String userId, {String? deckId}) async {
    final cards = await getCards(userId, deckId: deckId);
    final meta = await getSyncMeta(userId);
    final today = _today(meta);
    final due =
        cards
            .where(
              (c) =>
                  !c.learningMode &&
                  c.nextReviewDate != null &&
                  c.nextReviewDate!.compareTo(_formatDate(today)) <= 0,
            )
            .toList()
          ..sort(
            (a, b) =>
                (a.nextReviewDate ?? '').compareTo(b.nextReviewDate ?? ''),
          );
    final learning =
        cards
            .where(
              (c) =>
                  c.learningMode &&
                  c.nextReviewDate != null &&
                  c.nextReviewDate!.compareTo(_formatDate(today)) <= 0,
            )
            .toList()
          ..sort((a, b) {
            final step = a.learningStep.compareTo(b.learningStep);
            if (step != 0) return step;
            return (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                .compareTo(
                  b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
                );
          });

    final queue = List<LocalCard>.from(due);
    for (final card in learning) {
      final offset = 1 << card.learningStep;
      final position = offset.clamp(0, queue.length).toInt();
      queue.insert(position, card);
    }
    return queue.map(_toReviewCard).toList();
  }

  Future<List<ReviewCard>> getNewQueue(
    String userId, {
    String? deckId,
    int limit = 10,
  }) async {
    final cards = await getCards(userId, deckId: deckId);
    final queue = cards.where((c) => c.stage == 0 && !c.learningMode).toList()
      ..sort(
        (a, b) => (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
    return queue.take(limit).map(_toReviewCard).toList();
  }

  Future<List<Deck>> getDeckSummaries(String userId) async {
    final decks = await getDecks(userId);
    final cards = await getCards(userId);
    final meta = await getSyncMeta(userId);
    final today = _formatDate(_today(meta));
    return decks.map((deck) {
      final deckCards = cards.where((c) => c.deckId == deck.id).toList();
      final due = deckCards
          .where(
            (c) =>
                c.nextReviewDate != null &&
                c.nextReviewDate!.compareTo(today) <= 0,
          )
          .length;
      final newCount = deckCards
          .where((c) => c.stage == 0 && !c.learningMode)
          .length;
      final mastered = deckCards.where((c) => c.stage >= 5).length;
      final distribution = _distribution(
        deckCards.map((c) => c.stage).toList(),
      );
      final dueDistribution = _distribution(
        deckCards
            .where(
              (c) =>
                  c.nextReviewDate != null &&
                  c.nextReviewDate!.compareTo(today) <= 0,
            )
            .map((c) => c.stage)
            .toList(),
      );
      return Deck(
        id: deck.id,
        name: deck.name,
        cardCount: deckCards.length,
        dueCount: due,
        newCount: newCount,
        masteredCount: mastered,
        stageDistribution: distribution,
        dueStageDistribution: dueDistribution,
        createdAt: deck.createdAt?.toIso8601String() ?? '',
      );
    }).toList();
  }

  Future<OverviewStats> getOverviewStats(String userId) async {
    final decks = await getDecks(userId);
    final cards = await getCards(userId);
    final logs = await _getLogs(userId);
    final meta = await getSyncMeta(userId);
    final refreshTime = meta?.refreshTime ?? '04:00:00';
    final today = _formatDate(_today(meta));
    final dueToday = cards
        .where(
          (c) =>
              c.nextReviewDate != null &&
              c.nextReviewDate!.compareTo(today) <= 0,
        )
        .length;
    final reviewedToday = logs
        .where(
          (l) =>
              !l.isNewCard && _onRefreshDay(l.reviewedAt, refreshTime, today),
        )
        .length;
    final learnedToday = logs
        .where(
          (l) =>
              l.isNewCard &&
              l.rating == 'FAMILIAR' &&
              _onRefreshDay(l.reviewedAt, refreshTime, today),
        )
        .length;
    final stages = cards.map((c) => c.stage).toList();
    return OverviewStats(
      totalCards: cards.length,
      totalDecks: decks.length,
      dueToday: dueToday,
      reviewedToday: reviewedToday,
      learnedToday: learnedToday,
      masteredCards: stages.where((s) => s >= 5).length,
      newCards: cards.where((c) => c.stage == 0 && !c.learningMode).length,
      learningCards: stages.where((s) => s < 5).length,
      stageDistribution: _distribution(stages),
      dueStageDistribution: _distribution(
        cards
            .where(
              (c) =>
                  c.nextReviewDate != null &&
                  c.nextReviewDate!.compareTo(today) <= 0,
            )
            .map((c) => c.stage)
            .toList(),
      ),
    );
  }

  Future<DeckStats> getDeckStats(String userId, String deckId) async {
    final cards = await getCards(userId, deckId: deckId);
    final decks = await getDecks(userId);
    final deck = decks.where((d) => d.id == deckId).firstOrNull;
    final meta = await getSyncMeta(userId);
    final refreshTime = meta?.refreshTime ?? '04:00:00';
    final today = _formatDate(_today(meta));
    final logs = await _getLogs(userId);
    final stages = cards.map((c) => c.stage).toList();
    final cardIds = cards.map((c) => c.id).toSet();
    final reviewedToday = logs
        .where(
          (l) =>
              cardIds.contains(l.cardId) &&
              !l.isNewCard &&
              _onRefreshDay(l.reviewedAt, refreshTime, today),
        )
        .length;
    return DeckStats(
      deckId: deckId,
      deckName: deck?.name ?? '',
      totalCards: cards.length,
      dueToday: cards
          .where(
            (c) =>
                c.nextReviewDate != null &&
                c.nextReviewDate!.compareTo(today) <= 0,
          )
          .length,
      reviewedToday: reviewedToday,
      newCards: cards.where((c) => c.stage == 0 && !c.learningMode).length,
      learningCards: cards.where((c) => c.learningMode).length,
      masteredCards: stages.where((s) => s >= 5).length,
      stageDistribution: _distribution(stages),
      dueStageDistribution: _distribution(
        cards
            .where(
              (c) =>
                  c.nextReviewDate != null &&
                  c.nextReviewDate!.compareTo(today) <= 0,
            )
            .map((c) => c.stage)
            .toList(),
      ),
    );
  }

  Future<List<TrendPoint>> getTrend(String userId, {int days = 30}) async {
    final logs = await _getLogs(userId);
    final meta = await getSyncMeta(userId);
    final refreshTime = meta?.refreshTime ?? '04:00:00';
    final today = _today(meta);
    final points = <TrendPoint>[];
    for (var i = days - 1; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateKey = _formatDate(date);
      final dayLogs = logs.where(
        (l) => _onRefreshDay(l.reviewedAt, refreshTime, dateKey),
      );
      points.add(
        TrendPoint(
          date: dateKey,
          reviewed: dayLogs.where((l) => !l.isNewCard).length,
          learned: dayLogs
              .where((l) => l.isNewCard && l.rating == 'FAMILIAR')
              .length,
        ),
      );
    }
    return points;
  }

  Future<void> saveBootstrap({
    required String userId,
    required String email,
    required String refreshTime,
    required DateTime serverTime,
    required List<Map<String, dynamic>> decks,
    required List<Map<String, dynamic>> reviewLogs,
    int eventCursor = 0,
  }) async {
    final localTime = DateTime.now().toUtc();
    final clockOffset = serverTime.difference(localTime).inMilliseconds;

    await db.transaction(() async {
      await (db.delete(
        db.localCards,
      )..where((t) => t.userId.equals(userId))).go();
      await (db.delete(
        db.localDecks,
      )..where((t) => t.userId.equals(userId))).go();
      await (db.delete(db.localReviewLogs)..where(
            (t) =>
                t.userId.equals(userId) &
                (t.syncStatus.equals('SYNCED') |
                    t.syncStatus.equals('DISCARDED')),
          ))
          .go();

      for (final deckJson in decks) {
        final deckId = deckJson['id'] as String;
        await db
            .into(db.localDecks)
            .insertOnConflictUpdate(
              LocalDecksCompanion.insert(
                id: deckId,
                userId: userId,
                name: deckJson['name'] as String? ?? '',
                createdAt: Value(_dateTime(deckJson['created_at'])),
                updatedAt: Value(_dateTime(deckJson['updated_at'])),
              ),
            );
        for (final cardJson in (deckJson['cards'] as List? ?? const [])) {
          final map = cardJson as Map<String, dynamic>;
          await db
              .into(db.localCards)
              .insertOnConflictUpdate(
                LocalCardsCompanion.insert(
                  id: map['id'] as String,
                  deckId: deckId,
                  userId: userId,
                  front: map['front'] as String? ?? '',
                  back: map['back'] as String? ?? '',
                  stage: Value(_int(map['stage'])),
                  consecutiveFamiliar: Value(_int(map['consecutive_familiar'])),
                  nextReviewDate: Value(map['next_review_date'] as String?),
                  learningMode: Value(map['learning_mode'] as bool? ?? false),
                  reentryStage: Value(_intOrNull(map['reentry_stage'])),
                  learningStep: Value(_int(map['learning_step'])),
                  reviewVersion: Value(
                    BigInt.from(_int(map['review_version'])),
                  ),
                  createdAt: Value(_dateTime(map['created_at'])),
                  updatedAt: Value(_dateTime(map['updated_at'])),
                ),
              );
        }
      }

      for (final logJson in reviewLogs) {
        final map = logJson;
        final rating = map['rating'] as String? ?? 'FAMILIAR';
        final isNewCard =
            (map['is_new_card'] as bool?) ??
            (map['new_card'] as bool?) ??
            (rating == 'FAMILIAR' && _int(map['stage_before']) == 0);
        final clientRequestId = map['client_request_id'] as String?;
        if (clientRequestId != null) {
          await (db.delete(db.localReviewLogs)..where(
                (t) =>
                    t.userId.equals(userId) &
                    t.clientRequestId.equals(clientRequestId),
              ))
              .go();
        }
        await db
            .into(db.localReviewLogs)
            .insertOnConflictUpdate(
              LocalReviewLogsCompanion.insert(
                id: map['id'] as String,
                userId: userId,
                cardId: map['card_id'] as String,
                rating: rating,
                stageBefore: _int(map['stage_before']),
                stageAfter: _int(map['stage_after']),
                isNewCard: Value(isNewCard),
                reviewedAt:
                    _dateTime(map['reviewed_at']) ?? DateTime.now().toUtc(),
                clientRequestId: Value(clientRequestId),
                syncStatus: const Value('SYNCED'),
              ),
            );
      }

      await db
          .into(db.syncMeta)
          .insertOnConflictUpdate(
            SyncMetaCompanion.insert(
              userId: userId,
              email: Value(email),
              refreshTime: Value(refreshTime),
              lastBootstrapAt: Value(serverTime),
              clockOffsetMs: Value(clockOffset),
              lastEventCursor: Value(BigInt.from(eventCursor)),
            ),
          );
      await db
          .into(db.localSettings)
          .insertOnConflictUpdate(
            LocalSettingsCompanion.insert(
              userId: userId,
              email: email,
              refreshTime: Value(refreshTime),
              updatedAt: Value(serverTime),
            ),
          );
    });
  }

  Future<void> applyDelta({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await db.transaction(() async {
      final decks = (data['decks'] as List? ?? const [])
          .cast<Map<String, dynamic>>();
      for (final deckJson in decks) {
        final deckId = deckJson['id'] as String;
        await db
            .into(db.localDecks)
            .insertOnConflictUpdate(
              LocalDecksCompanion.insert(
                id: deckId,
                userId: userId,
                name: deckJson['name'] as String? ?? '',
                createdAt: Value(_dateTime(deckJson['created_at'])),
                updatedAt: Value(_dateTime(deckJson['updated_at'])),
              ),
            );
        for (final cardJson in (deckJson['cards'] as List? ?? const [])) {
          final map = cardJson as Map<String, dynamic>;
          await _upsertCardFromServer(userId, map);
        }
      }

      final changedCards = (data['changed_cards'] as List? ?? const [])
          .cast<Map<String, dynamic>>();
      for (final map in changedCards) {
        await _upsertCardFromServer(userId, map);
      }

      for (final logJson in (data['review_logs'] as List? ?? const [])) {
        final map = logJson as Map<String, dynamic>;
        final rating = map['rating'] as String? ?? 'FAMILIAR';
        final isNewCard =
            (map['is_new_card'] as bool?) ??
            (map['new_card'] as bool?) ??
            (rating == 'FAMILIAR' && _int(map['stage_before']) == 0);
        final clientRequestId = map['client_request_id'] as String?;
        if (clientRequestId != null) {
          await (db.delete(db.localReviewLogs)..where(
                (t) =>
                    t.userId.equals(userId) &
                    t.clientRequestId.equals(clientRequestId),
              ))
              .go();
        }
        await db
            .into(db.localReviewLogs)
            .insertOnConflictUpdate(
              LocalReviewLogsCompanion.insert(
                id: map['id'] as String,
                userId: userId,
                cardId: map['card_id'] as String,
                rating: rating,
                stageBefore: _int(map['stage_before']),
                stageAfter: _int(map['stage_after']),
                isNewCard: Value(isNewCard),
                reviewedAt:
                    _dateTime(map['reviewed_at']) ?? DateTime.now().toUtc(),
                clientRequestId: Value(clientRequestId),
                syncStatus: const Value('SYNCED'),
              ),
            );
      }

      final deletedDeckIds = (data['deleted_deck_ids'] as List? ?? const [])
          .cast<String>();
      if (deletedDeckIds.isNotEmpty) {
        await (db.delete(db.localDecks)..where(
              (t) => t.userId.equals(userId) & t.id.isIn(deletedDeckIds),
            ))
            .go();
        for (final deckId in deletedDeckIds) {
          await (db.delete(db.localCards)..where(
                (t) => t.userId.equals(userId) & t.deckId.equals(deckId),
              ))
              .go();
        }
      }

      final deletedCardIds = (data['deleted_card_ids'] as List? ?? const [])
          .cast<String>();
      if (deletedCardIds.isNotEmpty) {
        await (db.delete(db.localCards)..where(
              (t) => t.userId.equals(userId) & t.id.isIn(deletedCardIds),
            ))
            .go();
      }

      final deletedLogIds =
          (data['deleted_review_log_ids'] as List? ?? const []).cast<String>();
      if (deletedLogIds.isNotEmpty) {
        await (db.delete(
              db.localReviewLogs,
            )..where((t) => t.userId.equals(userId) & t.id.isIn(deletedLogIds)))
            .go();
      }

      final eventCursor = (data['event_cursor'] as num?)?.toInt() ?? 0;
      await (db.update(
        db.syncMeta,
      )..where((t) => t.userId.equals(userId))).write(
        SyncMetaCompanion(
          lastEventCursor: Value(BigInt.from(eventCursor)),
          lastBootstrapAt: Value(DateTime.now().toUtc()),
        ),
      );
    });
  }

  Future<void> _upsertCardFromServer(
    String userId,
    Map<String, dynamic> map,
  ) async {
    final cardId = map['id'] as String;
    final pending =
        await (db.select(db.localReviewLogs)..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.cardId.equals(cardId) &
                  t.syncStatus.equals('PENDING'),
            ))
            .get();
    final existing = await getLocalCard(userId, cardId);
    final serverVersion = BigInt.from(_int(map['review_version']));
    if (pending.isNotEmpty &&
        existing != null &&
        existing.reviewVersion.compareTo(serverVersion) >= 0) {
      return;
    }

    final deckId = map['deck_id'] as String? ?? existing?.deckId ?? '';
    await db
        .into(db.localCards)
        .insertOnConflictUpdate(
          LocalCardsCompanion.insert(
            id: cardId,
            deckId: deckId,
            userId: userId,
            front: map['front'] as String? ?? '',
            back: map['back'] as String? ?? '',
            stage: Value(_int(map['stage'])),
            consecutiveFamiliar: Value(_int(map['consecutive_familiar'])),
            nextReviewDate: Value(map['next_review_date'] as String?),
            learningMode: Value(map['learning_mode'] as bool? ?? false),
            reentryStage: Value(_intOrNull(map['reentry_stage'])),
            learningStep: Value(_int(map['learning_step'])),
            reviewVersion: Value(serverVersion),
            createdAt: Value(
              existing?.createdAt ?? _dateTime(map['created_at']),
            ),
            updatedAt: Value(
              _dateTime(map['updated_at']) ?? DateTime.now().toUtc(),
            ),
          ),
        );
  }

  Future<LocalCard?> getLocalCard(String userId, String cardId) async {
    final rows = await (db.select(
      db.localCards,
    )..where((t) => t.userId.equals(userId) & t.id.equals(cardId))).get();
    return rows.firstOrNull;
  }

  Future<void> applyLocalRating({
    required String userId,
    required FlashCard card,
    required ReviewResult result,
    required String clientRequestId,
    required DateTime ratedAt,
    required int reviewVersionBefore,
    required bool isNewCard,
  }) async {
    await db.transaction(() async {
      await db
          .into(db.localCards)
          .insertOnConflictUpdate(
            LocalCardsCompanion.insert(
              id: card.id,
              deckId: card.deckId,
              userId: userId,
              front: card.front,
              back: card.back,
              stage: Value(card.stage),
              consecutiveFamiliar: Value(card.consecutiveFamiliar),
              nextReviewDate: Value(card.nextReviewDate),
              learningMode: Value(card.learningMode),
              reentryStage: Value(card.reentryStage),
              learningStep: Value(card.learningStep),
              reviewVersion: Value(BigInt.from(card.reviewVersion)),
              createdAt: Value(_dateTimeFromString(card.createdAt)),
              updatedAt: Value(ratedAt),
            ),
          );
      await db
          .into(db.localReviewLogs)
          .insertOnConflictUpdate(
            LocalReviewLogsCompanion.insert(
              id: clientRequestId,
              userId: userId,
              cardId: card.id,
              rating: result.rating,
              stageBefore: result.stageBefore,
              stageAfter: result.stageAfter,
              isNewCard: Value(isNewCard),
              reviewedAt: ratedAt,
              clientRequestId: Value(clientRequestId),
              reviewVersion: Value(BigInt.from(reviewVersionBefore)),
              syncStatus: const Value('PENDING'),
            ),
          );
    });
  }

  Future<List<LocalReviewLog>> getPendingRatings(String userId) async {
    final rows =
        await (db.select(db.localReviewLogs)..where(
              (t) => t.userId.equals(userId) & t.syncStatus.equals('PENDING'),
            ))
            .get();
    rows.sort((a, b) => a.reviewedAt.compareTo(b.reviewedAt));
    return rows;
  }

  Future<void> markSynced(String userId, String clientRequestId) async {
    await _updateLogStatus(userId, clientRequestId, 'SYNCED');
  }

  Future<void> markDiscarded(String userId, String clientRequestId) async {
    await _updateLogStatus(userId, clientRequestId, 'DISCARDED');
  }

  Future<void> discardAllPending(String userId) async {
    await (db.update(db.localReviewLogs)..where(
          (t) => t.userId.equals(userId) & t.syncStatus.equals('PENDING'),
        ))
        .write(LocalReviewLogsCompanion(syncStatus: const Value('DISCARDED')));
  }

  Future<void> updateCardFromServer(String userId, ReviewCard card) async {
    final pending =
        await (db.select(db.localReviewLogs)..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.cardId.equals(card.id) &
                  t.syncStatus.equals('PENDING'),
            ))
            .get();
    final existing = await getLocalCard(userId, card.id);
    final serverVersion = BigInt.from(card.reviewVersion);
    if (pending.isNotEmpty &&
        existing != null &&
        existing.reviewVersion.compareTo(serverVersion) >= 0) {
      return;
    }
    final created = existing?.createdAt;
    await db
        .into(db.localCards)
        .insertOnConflictUpdate(
          LocalCardsCompanion.insert(
            id: card.id,
            deckId: card.deckId,
            userId: userId,
            front: card.front,
            back: card.back ?? '',
            stage: Value(card.stage),
            consecutiveFamiliar: Value(card.consecutiveFamiliar),
            nextReviewDate: Value(card.nextReviewDate),
            learningMode: Value(card.learningMode),
            reentryStage: Value(card.reentryStage),
            learningStep: Value(card.learningStep),
            reviewVersion: Value(BigInt.from(card.reviewVersion)),
            createdAt: Value(created),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }

  Future<void> removeCard(String userId, String cardId) async {
    await (db.delete(
      db.localCards,
    )..where((t) => t.userId.equals(userId) & t.id.equals(cardId))).go();
  }

  Future<void> clearUserData(String userId) async {
    await db.transaction(() async {
      await (db.delete(
        db.localCards,
      )..where((t) => t.userId.equals(userId))).go();
      await (db.delete(
        db.localDecks,
      )..where((t) => t.userId.equals(userId))).go();
      await (db.delete(
        db.localReviewLogs,
      )..where((t) => t.userId.equals(userId))).go();
      await (db.delete(
        db.localSettings,
      )..where((t) => t.userId.equals(userId))).go();
      await (db.delete(
        db.syncMeta,
      )..where((t) => t.userId.equals(userId))).go();
    });
  }

  Future<SyncMetaData?> getActiveSyncMeta() async {
    final rows = await db.select(db.syncMeta).get();
    rows.sort(
      (a, b) => (b.lastBootstrapAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(
            a.lastBootstrapAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          ),
    );
    return rows.firstOrNull;
  }

  Future<SyncMetaData?> getSyncMeta(String userId) async {
    final rows = await (db.select(
      db.syncMeta,
    )..where((t) => t.userId.equals(userId))).get();
    return rows.firstOrNull;
  }

  Future<LocalSetting?> getSettings(String userId) async {
    final rows = await (db.select(
      db.localSettings,
    )..where((t) => t.userId.equals(userId))).get();
    return rows.firstOrNull;
  }

  Future<void> saveSettings(
    String userId,
    String email,
    String refreshTime,
  ) async {
    await db
        .into(db.localSettings)
        .insertOnConflictUpdate(
          LocalSettingsCompanion.insert(
            userId: userId,
            email: email,
            refreshTime: Value(refreshTime),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
    await db
        .into(db.syncMeta)
        .insertOnConflictUpdate(
          SyncMetaCompanion.insert(
            userId: userId,
            email: Value(email),
            refreshTime: Value(refreshTime),
          ),
        );
  }

  Future<List<LocalReviewLog>> _getLogs(String userId) async {
    final rows = await (db.select(
      db.localReviewLogs,
    )..where((t) => t.userId.equals(userId))).get();

    final clientDeduped = <LocalReviewLog>[];
    final byClientId = <String, LocalReviewLog>{};
    for (final log in rows) {
      if (log.syncStatus == 'DISCARDED') continue;
      final clientId = log.clientRequestId;
      if (clientId != null) {
        final existing = byClientId[clientId];
        if (existing != null) {
          if (_isLocalMirror(log) && !_isLocalMirror(existing)) continue;
          if (!_isLocalMirror(log) && _isLocalMirror(existing)) {
            final index = clientDeduped.indexOf(existing);
            clientDeduped[index] = log;
            byClientId[clientId] = log;
          }
          continue;
        }
        byClientId[clientId] = log;
      }
      clientDeduped.add(log);
    }

    final result = <LocalReviewLog>[];
    final byEvent = <String, LocalReviewLog>{};
    for (final log in clientDeduped) {
      final eventKey = _reviewLogEventKey(log);
      final existing = byEvent[eventKey];
      if (existing != null) {
        if (_isLocalMirror(log) && !_isLocalMirror(existing)) continue;
        if (!_isLocalMirror(log) && _isLocalMirror(existing)) {
          final index = result.indexOf(existing);
          result[index] = log;
          byEvent[eventKey] = log;
        }
        continue;
      }
      byEvent[eventKey] = log;
      result.add(log);
    }
    return result;
  }

  bool _isLocalMirror(LocalReviewLog log) =>
      log.clientRequestId != null && log.clientRequestId == log.id;

  String _reviewLogEventKey(LocalReviewLog log) {
    final reviewedAt = log.reviewedAt.toUtc();
    final reviewedSecond = DateTime.utc(
      reviewedAt.year,
      reviewedAt.month,
      reviewedAt.day,
      reviewedAt.hour,
      reviewedAt.minute,
      reviewedAt.second,
    ).microsecondsSinceEpoch;
    return [
      log.cardId,
      log.rating,
      log.stageBefore,
      log.stageAfter,
      reviewedSecond,
      log.isNewCard,
    ].join('|');
  }

  Future<void> _updateLogStatus(
    String userId,
    String clientRequestId,
    String status,
  ) async {
    await (db.update(db.localReviewLogs)..where(
          (t) =>
              t.userId.equals(userId) &
              t.clientRequestId.equals(clientRequestId) &
              t.syncStatus.equals('PENDING'),
        ))
        .write(LocalReviewLogsCompanion(syncStatus: Value(status)));
  }

  DateTime _serverNow(SyncMetaData? meta) {
    final local = DateTime.now().toUtc();
    if (meta == null) return local;
    return local.add(Duration(milliseconds: meta.clockOffsetMs));
  }

  DateTime _today(SyncMetaData? meta) {
    return LocalSchedulingEngine.calculateToday(
      _serverNow(meta),
      meta?.refreshTime ?? '04:00:00',
    );
  }

  FlashCard _toFlashCard(LocalCard card) {
    return FlashCard(
      id: card.id,
      deckId: card.deckId,
      front: card.front,
      back: card.back,
      stage: card.stage,
      nextReviewDate: card.nextReviewDate,
      learningMode: card.learningMode,
      consecutiveFamiliar: card.consecutiveFamiliar,
      learningStep: card.learningStep,
      reentryStage: card.reentryStage,
      due: card.nextReviewDate != null,
      createdAt: card.createdAt?.toIso8601String() ?? '',
      reviewVersion: card.reviewVersion.toInt(),
    );
  }

  ReviewCard _toReviewCard(LocalCard card) {
    return ReviewCard(
      id: card.id,
      deckId: card.deckId,
      front: card.front,
      back: card.back,
      stage: card.stage,
      learningMode: card.learningMode,
      consecutiveFamiliar: card.consecutiveFamiliar,
      learningStep: card.learningStep,
      reentryStage: card.reentryStage,
      nextReviewDate: card.nextReviewDate,
      reviewVersion: card.reviewVersion.toInt(),
    );
  }

  List<int> _distribution(List<int> stages) {
    final result = List<int>.filled(9, 0);
    for (final stage in stages) {
      if (stage >= 0 && stage < 9) result[stage] += 1;
    }
    return result;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  bool _onRefreshDay(DateTime reviewedAt, String refreshTime, String day) {
    final refreshDay = LocalSchedulingEngine.calculateToday(
      reviewedAt,
      refreshTime,
    );
    return _formatDate(refreshDay) == day;
  }

  DateTime? _dateTime(dynamic value) {
    return parseServerDateTime(value);
  }

  DateTime? _dateTimeFromString(String? value) {
    if (value == null || value.isEmpty) return null;
    return parseServerDateTime(value);
  }

  int _int(dynamic value) => (value as num?)?.toInt() ?? 0;

  int? _intOrNull(dynamic value) => (value as num?)?.toInt();
}
