import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../offline/offline_repository.dart';
import '../../offline/providers.dart';
import '../../shared/providers/data_refresh_provider.dart';
import '../../shared/providers/dual_channel_loader.dart';
import '../../sync/providers.dart';
import '../../sync/sync_service.dart';
import '../repositories/card_repository.dart';
import '../models/card.dart';

class CardListArgs {
  final String deckId;
  final String filter;

  const CardListArgs(this.deckId, this.filter);

  @override
  bool operator ==(Object other) {
    return other is CardListArgs &&
        other.deckId == deckId &&
        other.filter == filter;
  }

  @override
  int get hashCode => Object.hash(deckId, filter);
}

class CardListNotifier extends StateNotifier<AsyncValue<List<FlashCard>>> {
  final CardRepository _repository;
  final CardListArgs args;
  final OfflineRepository? offline;
  final SyncService? sync;
  final DualChannelLoader _loader;

  String _query = '';
  int _requestVersion = 0;

  CardListNotifier(this._repository, this.args, {this.offline, this.sync})
    : _loader = DualChannelLoader(offline: offline, sync: sync),
      super(const AsyncValue.loading()) {
    if (offline != null) {
      _loadLocalCards();
    } else {
      loadCards();
    }
  }

  Future<void> setSearchQuery(String rawQuery) async {
    final query = rawQuery.trim();
    if (query == _query) return;
    _query = query;
    await loadCards();
  }

  // 加载骨架收敛为 DualChannelLoader（架构评审 C1）；
  // fetchOnline 需在离线分支也拉全量分页，故封装 _fetchAllCards 的返回值。
  Future<void> loadCards() async {
    final requestVersion = ++_requestVersion;
    await _loader.load<List<FlashCard>>(
      fetchOnline: () => _fetchAllCards(
        requestVersion,
        (value) => state = value,
      ),
      fetchLocal: (userId) => _localCards(userId),
      setState: (value) => state = value,
      currentState: state,
      isStale: () => requestVersion != _requestVersion,
    );
  }

  // 在线拉取（含搜索时跨分页合并；分页间渐进更新 UI，与旧行为一致）。
  Future<List<FlashCard>> _fetchAllCards(
    int requestVersion,
    void Function(AsyncValue<List<FlashCard>>) setState,
  ) async {
    final first = await _fetchCards();
    if (requestVersion != _requestVersion) return const [];
    var cards = _parseCards(first);
    setState(AsyncValue.data(cards));
    if (_query.isEmpty) return cards;
    final totalPages = (first['total_pages'] as num?)?.toInt() ?? 1;
    for (var page = 1; page < totalPages; page++) {
      if (requestVersion != _requestVersion) return cards;
      final next = await _fetchCards(page: page);
      if (requestVersion != _requestVersion) return cards;
      cards = List<FlashCard>.from(cards)..addAll(_parseCards(next));
      setState(AsyncValue.data(cards));
    }
    return cards;
  }

  Future<Map<String, dynamic>> _fetchCards({int page = 0}) {
    if (_query.isEmpty) {
      return _repository.getDeckCards(
        args.deckId,
        page: page,
        size: 500,
        filter: args.filter,
      );
    }
    return _repository.getDeckCards(
      args.deckId,
      page: page,
      size: 500,
      filter: args.filter,
      query: _query,
    );
  }

  List<FlashCard> _parseCards(Map<String, dynamic> result) {
    final content = result['content'] as List<dynamic>? ?? const [];
    return content
        .map((c) => FlashCard.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<void> createCard(String front, String back) async {
    try {
      await _repository.createCard(args.deckId, front, back);
      await loadCards();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateCard(String cardId, String front, String back) async {
    try {
      await _repository.updateCard(cardId, front, back);
      await loadCards();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteCard(String cardId) async {
    try {
      await _repository.deleteCard(cardId);
      await loadCards();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteCards(List<String> cardIds) async {
    if (cardIds.isEmpty) return;
    try {
      const chunkSize = 1000;
      for (var i = 0; i < cardIds.length; i += chunkSize) {
        final end = i + chunkSize > cardIds.length
            ? cardIds.length
            : i + chunkSize;
        await _repository.batchDeleteCards(cardIds.sublist(i, end));
      }
      await loadCards();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // 数据变更重载统一委托 reloadDataAfterChange（架构评审 F4）。
  // 本地路径复用 _loadLocalCards（内部自带 requestVersion 防抖）。
  Future<void> reloadAfterDataChange() async {
    await reloadDataAfterChange(
      offline: offline,
      reloadOnline: loadCards,
      reloadLocal: (_) => _loadLocalCards(),
    );
  }

  // 构造时初始加载与本地重载共用：仅读本地，未登录直接返回（不发网络）。
  Future<void> _loadLocalCards() async {
    final requestVersion = ++_requestVersion;
    final previous = state.valueOrNull;
    if (previous == null) {
      state = const AsyncValue.loading();
    }
    try {
      final meta = await offline!.getActiveSyncMeta();
      if (meta == null) return;
      if (requestVersion != _requestVersion) return;
      state = AsyncValue.data(await _localCards(meta.userId));
    } catch (e, st) {
      if (requestVersion != _requestVersion) return;
      if (previous == null) {
        state = AsyncValue.error(e, st);
      } else {
        state = AsyncValue.data(previous);
      }
    }
  }

  Future<List<FlashCard>> _localCards(String userId) {
    return offline!.getFilteredFlashCards(
      userId,
      deckId: args.deckId,
      filter: args.filter,
      query: _query,
    );
  }
}

final cardListProvider =
    StateNotifierProvider.family<
      CardListNotifier,
      AsyncValue<List<FlashCard>>,
      CardListArgs
    >((ref, args) {
      final notifier = CardListNotifier(
        CardRepository(),
        args,
        offline: ref.watch(offlineRepositoryProvider),
        sync: ref.watch(syncServiceProvider),
      );
      listenDataVersion(ref, notifier.reloadAfterDataChange);
      return notifier;
    });
