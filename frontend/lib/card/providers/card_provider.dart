import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../offline/offline_repository.dart';
import '../../offline/providers.dart';
import '../../shared/providers/data_refresh_provider.dart';
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

  String _query = '';
  int _requestVersion = 0;

  CardListNotifier(this._repository, this.args, {this.offline, this.sync})
    : super(const AsyncValue.loading()) {
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

  Future<void> loadCards() async {
    final requestVersion = ++_requestVersion;
    final previous = state.valueOrNull;
    if (previous == null) {
      state = const AsyncValue.loading();
    }
    try {
      if (offline != null) {
        final meta = await offline!.getActiveSyncMeta();
        if (meta == null) {
          await _loadOnlineCards(requestVersion);
          return;
        }
        await sync!.refresh();
        if (requestVersion != _requestVersion) return;
        state = AsyncValue.data(await _localCards(meta.userId));
        return;
      }
      await _loadOnlineCards(requestVersion);
    } catch (e, st) {
      if (requestVersion != _requestVersion) return;
      if (previous == null) {
        state = AsyncValue.error(e, st);
      } else {
        state = AsyncValue.data(previous);
      }
    }
  }

  Future<void> _loadOnlineCards(int requestVersion) async {
    final first = await _fetchCards();
    if (requestVersion != _requestVersion) return;
    var cards = _parseCards(first);
    state = AsyncValue.data(cards);
    if (_query.isEmpty) return;
    final totalPages = (first['total_pages'] as num?)?.toInt() ?? 1;
    for (var page = 1; page < totalPages; page++) {
      if (requestVersion != _requestVersion) return;
      final next = await _fetchCards(page: page);
      if (requestVersion != _requestVersion) return;
      final merged = List<FlashCard>.from(cards)..addAll(_parseCards(next));
      cards = merged;
      state = AsyncValue.data(merged);
    }
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

  // 数据变更重载统一委托 reloadDataAfterChange（架构评审 F4）。
  // 本地路径复用 _loadLocalCards（内部自带 requestVersion 防抖）。
  Future<void> reloadAfterDataChange() async {
    await reloadDataAfterChange(
      offline: offline,
      reloadOnline: loadCards,
      reloadLocal: (_) => _loadLocalCards(),
    );
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
