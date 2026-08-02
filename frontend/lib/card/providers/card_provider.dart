import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../offline/offline_repository.dart';
import '../../offline/providers.dart';
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

  CardListNotifier(
    this._repository,
    this.args, {
    this.offline,
    this.sync,
  }) : super(const AsyncValue.loading()) {
    if (offline != null) {
      _loadLocalCards();
    } else {
      loadCards();
    }
  }

  Future<void> loadCards() async {
    if (offline != null) {
      final previous = state.valueOrNull;
      if (previous == null) {
        state = const AsyncValue.loading();
      }
      try {
        final meta = await offline!.getActiveSyncMeta();
        if (meta == null) throw StateError('no active local user');
        await sync!.bootstrap(userId: meta.userId);
        state = AsyncValue.data(
          await _localCards(meta.userId),
        );
      } catch (e, st) {
        if (previous == null) {
          state = AsyncValue.error(e, st);
        } else {
          state = AsyncValue.data(previous);
        }
      }
      return;
    }

    state = const AsyncValue.loading();
    try {
      final result = await _repository.getDeckCards(
        args.deckId,
        size: 500,
        filter: args.filter,
      );
      final content = result['content'] as List<dynamic>;
      final cards = content
          .map((c) => FlashCard.fromJson(c as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(cards);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
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

  Future<void> _loadLocalCards() async {
    try {
      final meta = await offline!.getActiveSyncMeta();
      if (meta == null) return;
      state = AsyncValue.data(await _localCards(meta.userId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<List<FlashCard>> _localCards(String userId) {
    return offline!.getFilteredFlashCards(
      userId,
      deckId: args.deckId,
      filter: args.filter,
    );
  }
}

final cardListProvider =
    StateNotifierProvider.family<
      CardListNotifier,
      AsyncValue<List<FlashCard>>,
      CardListArgs
    >((ref, args) => CardListNotifier(
          CardRepository(),
          args,
          offline: ref.watch(offlineRepositoryProvider),
          sync: ref.watch(syncServiceProvider),
        ));
