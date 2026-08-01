import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/card_repository.dart';
import '../models/card.dart';

class CardListNotifier extends StateNotifier<AsyncValue<List<FlashCard>>> {
  final CardRepository _repository;
  final String deckId;

  CardListNotifier(this._repository, this.deckId) : super(const AsyncValue.loading()) {
    loadCards();
  }

  Future<void> loadCards() async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.getDeckCards(deckId);
      final content = result['content'] as List<dynamic>;
      final cards = content.map((c) => FlashCard.fromJson(c as Map<String, dynamic>)).toList();
      state = AsyncValue.data(cards);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createCard(String front, String back) async {
    try {
      await _repository.createCard(deckId, front, back);
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
}

final cardListProvider = StateNotifierProvider.family<CardListNotifier, AsyncValue<List<FlashCard>>, String>(
  (ref, deckId) => CardListNotifier(CardRepository(), deckId),
);