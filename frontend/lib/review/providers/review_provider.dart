import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/review_repository.dart';
import '../models/review_card.dart';

class ReviewSessionState {
  final List<ReviewCard> cards;
  final int currentIndex;
  final bool isFlipped;
  final bool isLoading;
  final String? error;
  final int reviewedCount;
  final int totalCount;

  const ReviewSessionState({
    this.cards = const [],
    this.currentIndex = 0,
    this.isFlipped = false,
    this.isLoading = false,
    this.error,
    this.reviewedCount = 0,
    this.totalCount = 0,
  });

  ReviewCard? get currentCard =>
      currentIndex < cards.length ? cards[currentIndex] : null;

  bool get isComplete => currentIndex >= cards.length && cards.isNotEmpty;

  ReviewSessionState copyWith({
    List<ReviewCard>? cards,
    int? currentIndex,
    bool? isFlipped,
    bool? isLoading,
    String? error,
    int? reviewedCount,
    int? totalCount,
  }) {
    return ReviewSessionState(
      cards: cards ?? this.cards,
      currentIndex: currentIndex ?? this.currentIndex,
      isFlipped: isFlipped ?? this.isFlipped,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      reviewedCount: reviewedCount ?? this.reviewedCount,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class ReviewNotifier extends StateNotifier<ReviewSessionState> {
  final ReviewRepository _repository;

  ReviewNotifier(this._repository) : super(const ReviewSessionState());

  Future<void> loadDueCards({String? deckId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cards = await _repository.getDueCards(deckId: deckId);
      state = state.copyWith(
        cards: cards,
        currentIndex: 0,
        isFlipped: false,
        isLoading: false,
        reviewedCount: 0,
        totalCount: cards.length,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadNewCards({String? deckId, int limit = 10}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cards = await _repository.getNewCards(deckId: deckId, limit: limit);
      state = state.copyWith(
        cards: cards,
        currentIndex: 0,
        isFlipped: false,
        isLoading: false,
        reviewedCount: 0,
        totalCount: cards.length,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void flip() {
    state = state.copyWith(isFlipped: !state.isFlipped);
  }

  Future<void> rate(String rating) async {
    final card = state.currentCard;
    if (card == null) return;

    try {
      await _repository.rateCard(card.id, rating);
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        isFlipped: false,
        reviewedCount: state.reviewedCount + 1,
      );
    } catch (e) {
      state = state.copyWith(error: '评分失败: $e');
    }
  }

  void reset() {
    state = const ReviewSessionState();
  }
}

final reviewProvider = StateNotifierProvider<ReviewNotifier, ReviewSessionState>((ref) {
  return ReviewNotifier(ReviewRepository());
});