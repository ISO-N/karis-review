import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  });

  ReviewCard? get currentCard =>
      currentIndex < cards.length ? cards[currentIndex] : null;

  bool get isComplete => currentIndex >= cards.length && cards.isNotEmpty;

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
    );
  }
}

class ReviewNotifier extends StateNotifier<ReviewSessionState> {
  final ReviewRepository _repository;

  ReviewNotifier(this._repository) : super(const ReviewSessionState());

  Future<void> loadQueue({required String mode, String? deckId}) async {
    state = ReviewSessionState(
      mode: mode,
      deckId: deckId,
    ).copyWith(isLoading: true, error: null, ratingFailed: false);
    try {
      final cards = mode == 'new'
          ? await _repository.getNewCards(deckId: deckId)
          : await _repository.getDueCards(deckId: deckId);
      state = state.copyWith(
        cards: cards,
        currentIndex: 0,
        isFlipped: false,
        isLoading: false,
        reviewedCount: 0,
        totalCount: cards.length,
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
    final card = state.currentCard;
    if (card == null) return null;
    try {
      final result = await _repository.rateCard(card.id, rating);
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        isFlipped: false,
        reviewedCount: state.reviewedCount + 1,
        ratingFailed: false,
        lastResult: result,
      );
      return result;
    } catch (e) {
      state = state.copyWith(error: '评分失败，请检查网络后重试', ratingFailed: true);
      return null;
    }
  }

  void reset() {
    state = const ReviewSessionState();
  }
}

final reviewProvider =
    StateNotifierProvider<ReviewNotifier, ReviewSessionState>((ref) {
      return ReviewNotifier(ReviewRepository());
    });
