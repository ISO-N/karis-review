import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../offline/offline_repository.dart';
import '../../offline/providers.dart';
import '../../shared/providers/data_refresh_provider.dart';
import '../../shared/providers/dual_channel_loader.dart';
import '../../sync/providers.dart';
import '../../sync/sync_service.dart';
import '../repositories/deck_repository.dart';
import '../models/deck.dart';

class DeckListNotifier extends StateNotifier<AsyncValue<List<Deck>>> {
  final DeckRepository _repository;
  final OfflineRepository? offline;
  final SyncService? sync;
  final DualChannelLoader _loader;

  DeckListNotifier(this._repository, {this.offline, this.sync})
    : _loader = DualChannelLoader(offline: offline, sync: sync),
      super(const AsyncValue.loading()) {
    if (offline != null) {
      _loadLocal();
    } else {
      loadDecks();
    }
  }

  // 加载骨架收敛为 DualChannelLoader（架构评审 C1）。
  Future<void> loadDecks() async {
    await _loader.load<List<Deck>>(
      fetchOnline: () => _repository.getDecks(),
      fetchLocal: (userId) => offline!.getDeckSummaries(userId),
      setState: (value) => state = value,
      currentState: state,
    );
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
      await _loadLocalFor(meta.userId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _loadLocalFor(String userId) async {
    try {
      state = AsyncValue.data(await offline!.getDeckSummaries(userId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // 数据变更重载统一委托 reloadDataAfterChange（架构评审 F4）。
  Future<void> reloadAfterDataChange() async {
    await reloadDataAfterChange(
      offline: offline,
      reloadOnline: loadDecks,
      reloadLocal: _loadLocalFor,
    );
  }
}

final deckListProvider =
    StateNotifierProvider<DeckListNotifier, AsyncValue<List<Deck>>>((ref) {
      final notifier = DeckListNotifier(
        DeckRepository(),
        offline: ref.watch(offlineRepositoryProvider),
        sync: ref.watch(syncServiceProvider),
      );
      listenDataVersion(ref, notifier.reloadAfterDataChange);
      return notifier;
    });
