import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/deck_repository.dart';
import '../models/deck.dart';

class DeckListNotifier extends StateNotifier<AsyncValue<List<Deck>>> {
  final DeckRepository _repository;

  DeckListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadDecks();
  }

  Future<void> loadDecks() async {
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
}

final deckListProvider = StateNotifierProvider<DeckListNotifier, AsyncValue<List<Deck>>>((ref) {
  return DeckListNotifier(DeckRepository());
});