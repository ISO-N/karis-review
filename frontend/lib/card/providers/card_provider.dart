import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  CardListNotifier(this._repository, this.args)
    : super(const AsyncValue.loading()) {
    loadCards();
  }

  Future<void> loadCards() async {
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
}

final cardListProvider =
    StateNotifierProvider.family<
      CardListNotifier,
      AsyncValue<List<FlashCard>>,
      CardListArgs
    >((ref, args) => CardListNotifier(CardRepository(), args));
