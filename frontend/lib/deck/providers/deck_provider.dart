import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../offline/offline_repository.dart';
import '../../offline/providers.dart';
import '../../sync/providers.dart';
import '../../sync/sync_service.dart';
import '../repositories/deck_repository.dart';
import '../models/deck.dart';

class DeckListNotifier extends StateNotifier<AsyncValue<List<Deck>>> {
  final DeckRepository _repository;
  final OfflineRepository? offline;
  final SyncService? sync;

  DeckListNotifier(this._repository, {this.offline, this.sync})
    : super(const AsyncValue.loading()) {
    if (offline != null) {
      _loadLocal();
    } else {
      loadDecks();
    }
  }

  Future<void> loadDecks() async {
    if (offline != null) {
      final previous = state.valueOrNull;
      if (previous == null) {
        state = const AsyncValue.loading();
      }
      try {
        final meta = await offline!.getActiveSyncMeta();
        if (meta == null) {
          state = AsyncValue.data(await _repository.getDecks());
          return;
        }
        await sync!.bootstrap(userId: meta.userId);
        state = AsyncValue.data(await offline!.getDeckSummaries(meta.userId));
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
      final decks = await _repository.getDecks();
      state = AsyncValue.data(decks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createDeck(String name) async {
    try {
      await _repository.createDeck(name);
      await loadDecks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateDeck(String id, String name) async {
    try {
      await _repository.updateDeck(id, name);
      await loadDecks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteDeck(String id) async {
    try {
      await _repository.deleteDeck(id);
      await loadDecks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _loadLocal() async {
    try {
      final meta = await offline!.getActiveSyncMeta();
      if (meta == null) return;
      state = AsyncValue.data(await offline!.getDeckSummaries(meta.userId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final deckListProvider =
    StateNotifierProvider<DeckListNotifier, AsyncValue<List<Deck>>>((ref) {
      return DeckListNotifier(
        DeckRepository(),
        offline: ref.watch(offlineRepositoryProvider),
        sync: ref.watch(syncServiceProvider),
      );
    });
