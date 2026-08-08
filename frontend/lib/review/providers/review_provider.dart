// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../card/models/card.dart';
import '../../offline/local_scheduling_engine.dart';
import '../../offline/offline_repository.dart';
import '../../offline/providers.dart';
import '../../shared/providers/data_refresh_provider.dart';
import '../../shared/scheduling/scheduling_constants.dart';
import '../../sync/providers.dart';
import '../../sync/repositories/sync_repository.dart';
import '../../sync/sync_service.dart';
import '../repositories/review_repository.dart';
import '../models/review_card.dart';

class ReviewSessionState {
  final String mode;
  final String? deckId;
  final List<ReviewCard> cards;
  final int currentIndex;
  final bool isFlipped;
  final bool isLoading;
  final String? error;
  final bool ratingFailed;
  final int reviewedCount;
  final int totalCount;
  final ReviewResult? lastResult;
  final String? sessionId;
  final int cursor;
  final bool hasMore;
  final int serverTotal;
  final bool loadingMore;
  final String queueSource;
  final bool isRating;
  final int pendingSyncCount;

  const ReviewSessionState({
    this.mode = 'due',
    this.deckId,
    this.cards = const [],
    this.currentIndex = 0,
    this.isFlipped = false,
    this.isLoading = false,
    this.error,
    this.ratingFailed = false,
    this.reviewedCount = 0,
    this.totalCount = 0,
    this.lastResult,
    this.sessionId,
    this.cursor = 0,
    this.hasMore = false,
    this.serverTotal = 0,
    this.loadingMore = false,
    this.queueSource = 'local',
    this.isRating = false,
    this.pendingSyncCount = 0,
  });

  ReviewCard? get currentCard =>
      currentIndex < cards.length ? cards[currentIndex] : null;

  /// 当前第几张（从 1 计），UI 进度显示用，避免各页自算。
  int get currentNumber => currentIndex + 1;

  bool get isComplete =>
      !hasMore && currentIndex >= cards.length && cards.isNotEmpty;

  int get remaining => cards.length - currentIndex;

  int get sessionTotal => serverTotal > 0 ? serverTotal : totalCount;

  ReviewSessionState copyWith({
    String? mode,
    String? deckId,
    List<ReviewCard>? cards,
    int? currentIndex,
    bool? isFlipped,
    bool? isLoading,
    String? error,
    bool? ratingFailed,
    int? reviewedCount,
    int? totalCount,
    ReviewResult? lastResult,
    bool clearLastResult = false,
    String? sessionId,
    bool clearSessionId = false,
    int? cursor,
    bool? hasMore,
    int? serverTotal,
    bool? loadingMore,
    String? queueSource,
    bool? isRating,
    int? pendingSyncCount,
  }) {
    return ReviewSessionState(
      mode: mode ?? this.mode,
      deckId: deckId ?? this.deckId,
      cards: cards ?? this.cards,
      currentIndex: currentIndex ?? this.currentIndex,
      isFlipped: isFlipped ?? this.isFlipped,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      ratingFailed: ratingFailed ?? this.ratingFailed,
      reviewedCount: reviewedCount ?? this.reviewedCount,
      totalCount: totalCount ?? this.totalCount,
      lastResult: clearLastResult ? null : (lastResult ?? this.lastResult),
      sessionId: clearSessionId ? null : (sessionId ?? this.sessionId),
      cursor: cursor ?? this.cursor,
      hasMore: hasMore ?? this.hasMore,
      serverTotal: serverTotal ?? this.serverTotal,
      loadingMore: loadingMore ?? this.loadingMore,
      queueSource: queueSource ?? this.queueSource,
      isRating: isRating ?? this.isRating,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
    );
  }
}

class ReviewNotifier extends StateNotifier<ReviewSessionState> {
  final ReviewRepository _repository;
  final OfflineRepository? _offline;
  final SyncRepository? _sync;
  final SyncService? _syncService;
  final void Function()? _onDataChanged;
  bool _ratingInFlight = false;
  Timer? _syncDebounce;
  static const Duration _syncDelay = Duration(milliseconds: 800);

  ReviewNotifier(
    this._repository, {
    OfflineRepository? offline,
    SyncRepository? sync,
    SyncService? syncService,
    void Function()? onDataChanged,
  }) : _offline = offline,
       _sync = sync,
       _syncService = syncService,
       _onDataChanged = onDataChanged,
       super(const ReviewSessionState());
  Future<void> loadQueue({
    required String mode,
    String? deckId,
    int limit = 10,
  }) async {
    if (_offline == null || _sync == null || _syncService == null) {
      await _loadRemoteQueue(mode: mode, deckId: deckId, limit: limit);
      return;
    }

    state = ReviewSessionState(
      mode: mode,
      deckId: deckId,
    ).copyWith(isLoading: true, error: null, ratingFailed: false);
    final userId = await _activeUserId();
    if (userId != null) {
      final pending = await _offline.getPendingRatings(userId);
      if (pending.isNotEmpty) {
        try {
          await _syncService.syncPending(userId: userId);
          _onDataChanged?.call();
        } catch (_) {}
        final remaining = await _offline.getPendingRatings(userId);
        if (remaining.isNotEmpty) {
          await _loadLocalQueue(mode: mode, deckId: deckId);
          return;
        }
      }
    }
    try {
      final page = await _sync.createReviewSession(
        mode: mode,
        deckId: deckId,
        batchSize: limit,
      );
      final cards = _parseCards(page['cards']);
      final serverTotal = (page['total'] as num?)?.toInt() ?? cards.length;
      final currentUserId = userId ?? await _activeUserId();
      if (currentUserId != null) {
        for (final card in cards) {
          await _offline.updateCardFromServer(currentUserId, card);
        }
      }
      state = state.copyWith(
        cards: cards,
        currentIndex: 0,
        isFlipped: false,
        isLoading: false,
        reviewedCount: 0,
        totalCount: serverTotal,
        serverTotal: serverTotal,
        cursor: (page['cursor'] as num?)?.toInt() ?? cards.length,
        hasMore: page['has_more'] as bool? ?? false,
        sessionId: page['session_id'] as String?,
        queueSource: 'server',
        error: null,
        ratingFailed: false,
        clearLastResult: true,
      );
      await _refreshPendingCount();
      unawaited(_maybeLoadMore());
    } catch (_) {
      await _loadLocalQueue(mode: mode, deckId: deckId);
    }
  }

  Future<void> loadMore() async {
    final sessionId = state.sessionId;
    if (sessionId == null || !state.hasMore || state.loadingMore) return;
    state = state.copyWith(loadingMore: true, error: null);
    try {
      final page = await _sync!.fetchReviewSessionPage(
        sessionId: sessionId,
        cursor: state.cursor,
        limit: 10,
      );
      final userId = await _activeUserId();
      final cards = _parseCards(page['cards']);
      if (userId != null) {
        for (final card in cards) {
          await _offline!.updateCardFromServer(userId, card);
        }
      }
      final existingIds = state.cards.map((c) => c.id).toSet();
      final appended = cards.where((c) => !existingIds.contains(c.id)).toList();
      state = state.copyWith(
        cards: [...state.cards, ...appended],
        cursor: (page['cursor'] as num?)?.toInt() ?? state.cursor,
        hasMore: page['has_more'] as bool? ?? false,
        serverTotal: (page['total'] as num?)?.toInt() ?? state.serverTotal,
        loadingMore: false,
      );
      unawaited(_maybeLoadMore());
    } catch (_) {
      await _appendLocalQueue();
    }
  }

  Future<void> _maybeLoadMore() async {
    if (state.remaining <= 5 && state.hasMore && !state.loadingMore) {
      await loadMore();
    }
  }

  Future<void> _appendLocalQueue() async {
    final userId = await _activeUserId();
    if (userId == null) {
      state = state.copyWith(loadingMore: false, hasMore: false);
      return;
    }
    try {
      final local = state.mode == 'new'
          ? await _offline!.getNewQueue(
              userId,
              deckId: state.deckId,
              limit: 500,
            )
          : await _offline!.getDueQueue(userId, deckId: state.deckId);
      final existingIds = state.cards.map((c) => c.id).toSet();
      final appended = local.where((c) => !existingIds.contains(c.id)).toList();
      state = state.copyWith(
        cards: [...state.cards, ...appended],
        hasMore: false,
        loadingMore: false,
        queueSource: 'local',
        serverTotal: state.serverTotal > 0
            ? state.serverTotal
            : state.cards.length + appended.length,
      );
    } catch (_) {
      state = state.copyWith(loadingMore: false, hasMore: false);
    }
  }

  Future<void> _loadLocalQueue({required String mode, String? deckId}) async {
    final userId = await _activeUserId();
    if (userId == null) {
      state = state.copyWith(
        isLoading: false,
        error: '队列加载失败，请检查网络后重试',
        ratingFailed: false,
      );
      return;
    }
    try {
      final cards = mode == 'new'
          ? await _offline!.getNewQueue(userId, deckId: deckId, limit: 10)
          : await _offline!.getDueQueue(userId, deckId: deckId);
      state = state.copyWith(
        cards: cards,
        currentIndex: 0,
        isFlipped: false,
        isLoading: false,
        reviewedCount: 0,
        totalCount: cards.length,
        serverTotal: cards.length,
        hasMore: false,
        queueSource: 'local',
        error: null,
        ratingFailed: false,
        clearLastResult: true,
      );
      await _refreshPendingCount();
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: '队列加载失败，请检查网络后重试',
        ratingFailed: false,
      );
    }
  }

  Future<void> _loadRemoteQueue({
    required String mode,
    String? deckId,
    int limit = 10,
  }) async {
    state = ReviewSessionState(
      mode: mode,
      deckId: deckId,
    ).copyWith(isLoading: true, error: null, ratingFailed: false);
    try {
      final cards = mode == 'new'
          ? await _repository.getNewCards(deckId: deckId, limit: limit)
          : await _repository.getDueCards(deckId: deckId);
      state = state.copyWith(
        cards: cards,
        currentIndex: 0,
        isFlipped: false,
        isLoading: false,
        reviewedCount: 0,
        totalCount: cards.length,
        serverTotal: cards.length,
        hasMore: false,
        queueSource: 'remote',
        error: null,
        ratingFailed: false,
        clearLastResult: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '队列加载失败，请检查网络后重试',
        ratingFailed: false,
      );
    }
  }

  void flip() {
    state = state.copyWith(isFlipped: !state.isFlipped);
  }

  Future<ReviewResult?> rate(String rating) async {
    if (_ratingInFlight) return null;
    final card = state.currentCard;
    if (card == null) return null;
    _ratingInFlight = true;
    state = state.copyWith(isRating: true, error: null, ratingFailed: false);

    if (_offline == null || _syncService == null) {
      final result = await _rateRemote(card.id, rating);
      _ratingInFlight = false;
      state = state.copyWith(
        isRating: false,
        error: state.error,
        ratingFailed: state.ratingFailed,
      );
      return result;
    }

    try {
      final userId = await _activeUserId();
      if (userId == null) {
        throw StateError('no active local user');
      }
      final meta = await _offline.getSyncMeta(userId);
      final flash = _toFlashCard(card, refreshTime: meta?.refreshTime);
      // 评分时刻的学习来源快照（排程算法会返回变更后的卡，必须先取值）：
      // 学新阶段产生的重学（NEW）评分不计入「今日复习」。
      final originAtRating = flash.learningOrigin;
      debugPrint(
        '[KARIS-DBG] rate() card=${card.id} rating=$rating '
        'stage=${card.stage} learningMode=${card.learningMode} '
        'learningOrigin=${card.learningOrigin} queueSource=${state.queueSource}',
      );
      final outcome = LocalSchedulingEngine().rate(
        flash,
        rating,
        nowUtc: DateTime.now().toUtc(),
        refreshTime: meta?.refreshTime ?? '04:00:00',
      );
      final clientRequestId = const Uuid().v4();
      debugPrint(
        '[KARIS-DBG] rate() outcome wasNewCard=${outcome.wasNewCard} '
        'originAtRating=$originAtRating '
        'stageAfter=${outcome.result.stageAfter} '
        'learningModeAfter=${outcome.result.learningMode}',
      );
      await _offline.applyLocalRating(
        userId: userId,
        card: outcome.card,
        result: outcome.result,
        clientRequestId: clientRequestId,
        ratedAt: DateTime.now().toUtc(),
        reviewVersionBefore: outcome.reviewVersionBefore,
        isNewCard: outcome.wasNewCard,
        learningOrigin: originAtRating,
      );
      _onDataChanged?.call();

      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        isFlipped: false,
        reviewedCount: state.reviewedCount + 1,
        ratingFailed: false,
        lastResult: outcome.result,
        isRating: false,
      );
      // 进入学习模式（FORGET / VAGUE 重学、FAMILIAR 未达标）的卡片
      // 按 2^n 位置实时插回当前队列，避免依赖退出重进复习/学习页面才出现。
      if (outcome.result.learningMode) {
        _reinsertRelearningCard(_toReviewCard(outcome.card));
      }
      _ratingInFlight = false;
      if (state.isComplete) {
        unawaited(_flushSync(userId));
      } else {
        _scheduleSync(userId);
      }
      unawaited(_maybeLoadMore());
      return outcome.result;
    } catch (e) {
      _ratingInFlight = false;
      state = state.copyWith(
        error: '评分失败，请检查网络后重试',
        ratingFailed: true,
        isRating: false,
      );
      return null;
    }
  }

  Future<ReviewResult?> _rateRemote(String cardId, String rating) async {
    final before = state.currentCard;
    try {
      final result = await _repository.rateCard(cardId, rating);
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        isFlipped: false,
        reviewedCount: state.reviewedCount + 1,
        ratingFailed: false,
        lastResult: result,
        isRating: false,
      );
      // 远程评分响应携带 reentry_stage / learning_origin，
      // 重学卡按 step 0（紧邻位置）插回并保留来源与回归目标，
      // 避免会话内再次评分时来源快照丢失（本地统计误计）或重学类型判定错误。
      if (result.learningMode && before != null) {
        _reinsertRelearningCard(
          ReviewCard(
            id: before.id,
            deckId: before.deckId,
            front: before.front,
            back: before.back,
            stage: result.stageAfter,
            learningMode: true,
            consecutiveFamiliar: result.consecutiveFamiliar,
            learningStep: 0,
            reentryStage: result.reentryStage ?? before.reentryStage,
            nextReviewDate: result.nextReviewDate,
            reviewVersion: result.reviewVersion,
            learningOrigin: result.learningOrigin ?? before.learningOrigin,
          ),
        );
      }
      _onDataChanged?.call();
      return result;
    } catch (e) {
      state = state.copyWith(error: '评分失败，请检查网络后重试', ratingFailed: true);
      return null;
    }
  }

  void _scheduleSync(String userId) {
    _syncDebounce?.cancel();
    _syncDebounce = Timer(_syncDelay, () async {
      _syncDebounce = null;
      await _flushSync(userId);
    });
  }

  Future<void> _flushSync(String userId) async {
    try {
      await _syncService!.syncPending(userId: userId);
    } catch (_) {}
    await _refreshPendingCount();
    _onDataChanged?.call();
  }

  Future<void> _refreshPendingCount() async {
    final userId = await _activeUserId();
    if (userId == null) return;
    final pending = await _offline!.getPendingRatings(userId);
    // 数量未变化时保持原 state，避免无意义的通知引发整页重建。
    if (pending.length != state.pendingSyncCount) {
      state = state.copyWith(pendingSyncCount: pending.length);
    }
  }

  Future<String?> _activeUserId() async {
    final meta = await _offline!.getActiveSyncMeta();
    return meta?.userId;
  }

  /// 将进入学习模式（重学）的卡片按 2^n 位置实时插回当前队列。
  ///
  /// 位置语义与 [OfflineRepository.getDueQueue] 一致：offset = 2^learningStep
  /// （SchedulingConstants.relearningInsertOffset），但以已消费的
  /// [ReviewSessionState.currentIndex] 为基准，只插入到待评卡之后，
  /// 避免把卡插回自己前面造成重复评分。
  void _reinsertRelearningCard(ReviewCard relearnCard) {
    final current = state.currentIndex;
    final remaining = state.cards.length - current;
    final offset =
        SchedulingConstants.relearningInsertOffset(relearnCard.learningStep)
            .clamp(0, remaining);
    final insertAt = current + offset;
    final cards = [...state.cards]..insert(insertAt, relearnCard);
    state = state.copyWith(cards: cards);
  }

  ReviewCard _toReviewCard(FlashCard card) {
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
      reviewVersion: card.reviewVersion,
      learningOrigin: card.learningOrigin,
    );
  }

  Future<void> removeStaleCard(String cardId) async {
    final index = state.cards.indexWhere((c) => c.id == cardId);
    if (index < 0) return;
    final cards = [...state.cards]..removeAt(index);
    final nextIndex = index < state.currentIndex
        ? state.currentIndex - 1
        : state.currentIndex;
    state = state.copyWith(
      cards: cards,
      currentIndex: nextIndex.clamp(0, cards.length),
      isFlipped: false,
    );
  }

  @override
  void dispose() {
    _syncDebounce?.cancel();
    super.dispose();
  }

  void reset() {
    state = const ReviewSessionState();
  }

  List<ReviewCard> _parseCards(dynamic value) {
    return (value as List? ?? const [])
        .map((c) => ReviewCard.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  FlashCard _toFlashCard(ReviewCard card, {String? refreshTime}) {
    final today = _formatDate(
      LocalSchedulingEngine.calculateToday(
        DateTime.now().toUtc(),
        refreshTime ?? '04:00:00',
      ),
    );
    return FlashCard(
      id: card.id,
      deckId: card.deckId,
      front: card.front,
      back: card.back ?? '',
      stage: card.stage,
      nextReviewDate: card.nextReviewDate,
      learningMode: card.learningMode,
      consecutiveFamiliar: card.consecutiveFamiliar,
      learningStep: card.learningStep,
      reentryStage: card.reentryStage,
      due:
          card.nextReviewDate != null &&
          card.nextReviewDate!.compareTo(today) <= 0,
      reviewVersion: card.reviewVersion,
      learningOrigin: card.learningOrigin,
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

final reviewProvider =
    StateNotifierProvider<ReviewNotifier, ReviewSessionState>((ref) {
      return ReviewNotifier(
        ReviewRepository(),
        offline: ref.watch(offlineRepositoryProvider),
        sync: ref.watch(syncRepositoryProvider),
        syncService: ref.watch(syncServiceProvider),
        onDataChanged: () =>
            ref.read(dataRefreshControllerProvider).notifyLocalChanged(),
      );
    });
