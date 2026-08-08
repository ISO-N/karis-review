import 'package:drift/drift.dart';

import '../../card/models/card.dart';
import '../../deck/models/deck.dart';
import '../../review/models/review_card.dart';
import '../../shared/scheduling/queue_composer.dart';
import '../../shared/scheduling/rating.dart';
import '../../shared/scheduling/scheduling_constants.dart';
import '../../shared/utils/app_timezone.dart';
import '../../shared/utils/date_utils.dart';
import '../../stats/models/stats.dart';
import 'database/app_database.dart';
import 'local_scheduling_engine.dart';
import 'offline_mappers.dart';
import 'offline_stats.dart';

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
    final meta = await getSyncMeta(userId);
    final today = AppDateUtils.formatDate(_today(meta));
    return cards.map((c) => flashCardFromLocal(c, today: today)).toList();
  }

  Future<List<FlashCard>> getFilteredFlashCards(
    String userId, {
    String? deckId,
    String filter = 'all',
    String query = '',
  }) async {
    final cards = await getCards(userId, deckId: deckId);
    final meta = await getSyncMeta(userId);
    final today = AppDateUtils.formatDate(_today(meta));
    final normalizedQuery = query.trim().toLowerCase();
    // 筛选口径委托 _isNewCard/_isDueCard 单一事实源（架构评审候选 3 的闭合：
    // 此前 due 分支漏排除学新重学卡、new 分支漏含 NEW 来源重学卡，导致
    // 筛选内容与计数（DeckStats 走同一谓词）不一致）。
    final filtered =
        switch (filter) {
          'due' => cards.where((c) => _isDueCard(c, today)),
          'learning' => cards.where((c) => c.learningMode),
          'new' =>
            cards.where(_isNewCard).toList()..sort(
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
    return filtered.map((c) => flashCardFromLocal(c, today: today)).toList();
  }

  Future<List<ReviewCard>> getDueQueue(String userId, {String? deckId}) async {
    final cards = await getCards(userId, deckId: deckId);
    final meta = await getSyncMeta(userId);
    final today = _today(meta);
    // 复习队列 = 非重学到期卡（本查询）+ REVIEW/null 重学卡（learning 查询），
    // 口径同后端 CardQueryPredicates.DUE_EXCLUDING_NEW；两分列是为了按 2^n 插位。
    final due =
        cards
            .where(
              (c) =>
                  !c.learningMode &&
                  c.nextReviewDate != null &&
                  c.nextReviewDate!.compareTo(AppDateUtils.formatDate(today)) <= 0,
            )
            .toList()
          ..sort(
            (a, b) {
              // 逾期优先：逾期天数多的排前面；同逾期天数内按日期升序（先到期的先）
              final aOverdue = today
                  .difference(DateTime.parse(a.nextReviewDate!))
                  .inDays;
              final bOverdue = today
                  .difference(DateTime.parse(b.nextReviewDate!))
                  .inDays;
              if (aOverdue != bOverdue) return bOverdue.compareTo(aOverdue);
              return (a.nextReviewDate ?? '').compareTo(b.nextReviewDate ?? '');
            },
          );
    final learning =
        cards
            .where(
              (c) =>
                  c.learningMode &&
                  (c.learningOrigin == 'REVIEW' || c.learningOrigin == null) &&
                  c.nextReviewDate != null &&
                  c.nextReviewDate!.compareTo(AppDateUtils.formatDate(today)) <= 0,
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

    // 插位语义统一走 QueueComposer（架构评审 F1），与 getNewQueue、
    // 会话内 _reinsertRelearningCard 同一实现。
    final queue = QueueComposer.interleave(
      queue: due,
      learningCards: learning,
      learningStepOf: (c) => c.learningStep,
    );
    return queue.map(reviewCardFromLocal).toList();
  }

  Future<List<ReviewCard>> getNewQueue(
    String userId, {
    String? deckId,
    int limit = 10,
  }) async {
    final cards = await getCards(userId, deckId: deckId);
    final meta = await getSyncMeta(userId);
    final today = AppDateUtils.formatDate(_today(meta));
    // 学新队列 = 待学新卡 + 学新阶段产生的重学卡（来源 NEW，按 2^n 间距插入），
    // 口径同后端 CardQueryPredicates.NEW_QUEUE；与 OfflineRepository.getDueQueue
    // 的重学插位语义一致。
    final newCards = cards.where((c) => c.stage == 0 && !c.learningMode).toList()
      ..sort(
        (a, b) => (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
    final learningNew = cards
        .where(
          (c) =>
              c.learningMode &&
              c.learningOrigin == 'NEW' &&
              c.nextReviewDate != null &&
              c.nextReviewDate!.compareTo(today) <= 0,
        )
        .toList()
      ..sort((a, b) {
        final step = a.learningStep.compareTo(b.learningStep);
        if (step != 0) return step;
        return (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0));
      });
    final queue = QueueComposer.interleave(
      queue: newCards,
      learningCards: learningNew,
      learningStepOf: (c) => c.learningStep,
    );
    return queue.take(limit).map(reviewCardFromLocal).toList();
  }

  Future<List<Deck>> getDeckSummaries(String userId) async {
    final decks = await getDecks(userId);
    final cards = await getCards(userId);
    final meta = await getSyncMeta(userId);
    final today = AppDateUtils.formatDate(_today(meta));
    return decks.map((deck) {
      final deckCards = cards.where((c) => c.deckId == deck.id).toList();
      final due = deckCards
          .where((c) => _isDueCard(c, today))
          .length;
      final newCount = deckCards.where(_isNewCard).length;
      final mastered = deckCards.where((c) => c.stage >= 5).length;
      final distribution = stageDistribution(
        deckCards.map((c) => c.stage).toList(),
      );
      final dueDistribution = stageDistribution(
        deckCards
            .where((c) => _isDueCard(c, today))
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
    final meta = await getSyncMeta(userId);
    final refreshTime = meta?.refreshTime ?? SchedulingConstants.defaultRefreshTime;
    final todayDate = _today(meta);
    final today = AppDateUtils.formatDate(todayDate);
    // 今日概览只需“今天”的日志；since 留 1 天余量覆盖刷新点偏移（业务日从
    // 刷新点开始，UTC 上可能跨前一天），SQL 层过滤避免全量加载。
    final logs = await _getLogs(
      userId,
      since: DateTime.utc(
        todayDate.year,
        todayDate.month,
        todayDate.day,
      ).subtract(const Duration(days: 1)),
    );
    final dueToday = cards.where((c) => _isDueCard(c, today)).length;
    // 口径谓词下沉 offline_stats（isReviewedTodayLog/isLearnedTodayLog，
    // 与后端 ReviewLogQueryPredicates 一致）。
    final reviewedToday = logs
        .where(
          (l) =>
              isReviewedTodayLog(l) &&
              isOnRefreshDay(l.reviewedAt, refreshTime, today),
        )
        .length;
    final learnedToday = logs
        .where(
          (l) =>
              isLearnedTodayLog(l) &&
              isOnRefreshDay(l.reviewedAt, refreshTime, today),
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
      newCards: cards.where(_isNewCard).length,
      learningCards: stages.where((s) => s < 5).length,
      stageDistribution: stageDistribution(stages),
      dueStageDistribution: stageDistribution(
        cards
            .where((c) => _isDueCard(c, today))
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
    final refreshTime = meta?.refreshTime ?? SchedulingConstants.defaultRefreshTime;
    final todayDate = _today(meta);
    final today = AppDateUtils.formatDate(todayDate);
    // 同 getOverviewStats：只需“今天”的日志，SQL 层过滤。
    final logs = await _getLogs(
      userId,
      since: DateTime.utc(
        todayDate.year,
        todayDate.month,
        todayDate.day,
      ).subtract(const Duration(days: 1)),
    );
    final stages = cards.map((c) => c.stage).toList();
    final cardIds = cards.map((c) => c.id).toSet();
    final reviewedToday = logs
        .where(
          (l) =>
              cardIds.contains(l.cardId) &&
              isReviewedTodayLog(l) &&
              isOnRefreshDay(l.reviewedAt, refreshTime, today),
        )
        .length;
    return DeckStats(
      deckId: deckId,
      deckName: deck?.name ?? '',
      totalCards: cards.length,
      dueToday: cards.where((c) => _isDueCard(c, today)).length,
      reviewedToday: reviewedToday,
      newCards: cards.where(_isNewCard).length,
      learningCards: cards.where((c) => c.learningMode).length,
      masteredCards: stages.where((s) => s >= 5).length,
      stageDistribution: stageDistribution(stages),
      dueStageDistribution: stageDistribution(
        cards
            .where((c) => _isDueCard(c, today))
            .map((c) => c.stage)
            .toList(),
      ),
    );
  }

  Future<List<TrendPoint>> getTrend(String userId, {int days = 30}) async {
    final meta = await getSyncMeta(userId);
    final refreshTime = meta?.refreshTime ?? SchedulingConstants.defaultRefreshTime;
    final today = _today(meta);
    // 只拉窗口内日志（留 1 天余量覆盖刷新点偏移），SQL 层过滤。
    final since = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: days + 1));
    final logs = await _getLogs(userId, since: since);
    // 单趟按业务日分组累加，替代原来的 30 次全量 where 扫描。
    final reviewedByDay = <String, int>{};
    final learnedByDay = <String, int>{};
    for (final log in logs) {
      final day = AppDateUtils.formatDate(
        LocalSchedulingEngine.calculateToday(log.reviewedAt, refreshTime),
      );
      // 口径同 offline_stats（后端 ReviewLogQueryPredicates）：
      // 今日新学 = 新卡 FAMILIAR；今日复习 = 非新卡且非 NEW 来源重学。
      // 学新阶段重学卡（is_new_card=false, origin='NEW'）两端都不计入复习。
      if (isLearnedTodayLog(log)) {
        learnedByDay[day] = (learnedByDay[day] ?? 0) + 1;
      } else if (isReviewedTodayLog(log)) {
        reviewedByDay[day] = (reviewedByDay[day] ?? 0) + 1;
      }
    }
    final points = <TrendPoint>[];
    for (var i = days - 1; i >= 0; i--) {
      final dateKey = AppDateUtils.formatDate(today.subtract(Duration(days: i)));
      points.add(
        TrendPoint(
          date: dateKey,
          reviewed: reviewedByDay[dateKey] ?? 0,
          learned: learnedByDay[dateKey] ?? 0,
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
                  learningOrigin: Value(map['learning_origin'] as String?),
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
        await _upsertLogFromServer(userId, logJson);
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
        await _upsertLogFromServer(userId, logJson as Map<String, dynamic>);
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
            learningOrigin: Value(map['learning_origin'] as String?),
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

  /// 服务端 review_log 落库（saveBootstrap 与 applyDelta 共用，架构评审 E1）：
  /// client_request_id 去重删除（服务端来源替换本地镜像）→ upsert 写入。
  Future<void> _upsertLogFromServer(
    String userId,
    Map<String, dynamic> map,
  ) async {
    final rating = map['rating'] as String? ?? Rating.familiar;
    final isNewCard =
        (map['is_new_card'] as bool?) ??
        (map['new_card'] as bool?) ??
        (rating == Rating.familiar && _int(map['stage_before']) == 0);
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
            learningOrigin: Value(map['learning_origin'] as String?),
            reviewedAt:
                _dateTime(map['reviewed_at']) ?? DateTime.now().toUtc(),
            clientRequestId: Value(clientRequestId),
            syncStatus: const Value('SYNCED'),
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
    String? learningOrigin,
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
              learningOrigin: Value(card.learningOrigin),
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
              learningOrigin: Value(learningOrigin),
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
            learningOrigin: Value(card.learningOrigin),
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

  Future<List<LocalReviewLog>> _getLogs(String userId, {DateTime? since}) async {
    final query = db.select(db.localReviewLogs)
      ..where((t) => t.userId.equals(userId));
    // 统计只需要窗口内的日志：在 SQL 层按 reviewedAt(UTC) 过滤，
    // 避免把该用户全量历史日志拉进内存（几万条时差距明显）。
    if (since != null) {
      query.where((t) => t.reviewedAt.isBiggerOrEqualValue(since));
    }
    final rows = await query.get();

    // 去重逻辑下沉 offline_stats.dedupeReviewLogs（架构评审 F5）：
    // 按 clientRequestId 与事件键两轮去重，服务端来源替换本地镜像。
    final result = dedupeReviewLogs(rows);
return result;
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
      meta?.refreshTime ?? SchedulingConstants.defaultRefreshTime,
    );
  }

  // 谓词单一事实源（架构评审候选 3）：对应后端
  // card/repository/CardQueryPredicates，两端口径必须一致。
  // 学新队列口径：待学新卡（stage=0 且非重学）+ 学新阶段重学卡（learning_origin='NEW'）。
  bool _isNewCard(LocalCard c) =>
      (c.stage == 0 && !c.learningMode) ||
      (c.learningMode && c.learningOrigin == 'NEW');

  // 复习队列/统计口径：已排期到期卡且非学新阶段重学（同后端 DUE_EXCLUDING_NEW）。
  bool _isDueCard(LocalCard c, String today) =>
      c.nextReviewDate != null &&
      c.nextReviewDate!.compareTo(today) <= 0 &&
      !(c.learningMode && c.learningOrigin == 'NEW');

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
