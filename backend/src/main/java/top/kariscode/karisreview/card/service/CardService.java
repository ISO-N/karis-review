package top.kariscode.karisreview.card.service;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import top.kariscode.karisreview.card.dto.CardCreateRequest;
import top.kariscode.karisreview.card.dto.CardResponse;
import top.kariscode.karisreview.card.dto.CardUpdateRequest;
import top.kariscode.karisreview.card.entity.Card;
import top.kariscode.karisreview.card.entity.SchedulingState;
import top.kariscode.karisreview.card.repository.CardRepository;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.common.util.DateUtils;
import top.kariscode.karisreview.deck.entity.Deck;
import top.kariscode.karisreview.deck.repository.DeckRepository;
import top.kariscode.karisreview.auth.entity.User;
import top.kariscode.karisreview.auth.repository.UserRepository;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

@Service
public class CardService {

    private final CardRepository cardRepository;
    private final DeckRepository deckRepository;
    private final UserRepository userRepository;

    public CardService(CardRepository cardRepository,
                       DeckRepository deckRepository,
                       UserRepository userRepository) {
        this.cardRepository = cardRepository;
        this.deckRepository = deckRepository;
        this.userRepository = userRepository;
    }
    public Page<CardResponse> getDeckCards(UUID userId, UUID deckId, int page, int size, String filter) {
        return getDeckCards(userId, deckId, page, size, filter, "");
    }

    public Page<CardResponse> getDeckCards(UUID userId, UUID deckId, int page, int size, String filter, String query) {
        if (!deckRepository.existsByIdAndUserId(deckId, userId)) {
            throw new BusinessException(404, "deck.notfound");
        }

        String effectiveFilter = filter == null ? "all" : filter;
        String normalizedQuery = normalizeSearchQuery(query);
        PageRequest pageRequest = PageRequest.of(page, size);
        LocalDate today = todayFor(userId);
        Page<Card> cards;
        if (normalizedQuery.isEmpty()) {
            cards = switch (effectiveFilter) {
                case "due" -> cardRepository
                        .findByDeckIdAndNextReviewDateNotNullAndNextReviewDateLessThanEqualOrderByNextReviewDateAsc(
                                deckId, today, pageRequest);
                case "learning" -> cardRepository
                        .findByDeckIdAndLearningModeTrueOrderByCreatedAtAsc(deckId, pageRequest);
                case "new" -> cardRepository.findNewByDeckIdOrderByCreatedAtDesc(deckId, pageRequest);
                default -> cardRepository.findByDeckIdOrderByCreatedAtAsc(deckId, pageRequest);
            };
        } else {
            String pattern = searchPattern(normalizedQuery);
            cards = switch (effectiveFilter) {
                case "due" -> cardRepository
                        .searchByDeckIdAndNextReviewDateNotNullAndNextReviewDateLessThanEqualOrderByNextReviewDateAsc(
                                deckId, today, pattern, pageRequest);
                case "learning" -> cardRepository
                        .searchByDeckIdAndLearningModeTrueOrderByCreatedAtAsc(deckId, pattern, pageRequest);
                case "new" -> cardRepository.searchNewByDeckIdOrderByCreatedAtDesc(deckId, pattern, pageRequest);
                default -> cardRepository.searchByDeckIdOrderByCreatedAtAsc(deckId, pattern, pageRequest);
            };
        }
        return cards.map(card -> toCardResponse(card, today));
    }

    @Transactional
    public CardResponse createCard(UUID userId, UUID deckId, CardCreateRequest request) {
        Deck deck = deckRepository.findByIdAndUserId(deckId, userId)
                .orElseThrow(() -> new BusinessException(404, "deck.notfound"));

        Card card = new Card();
        card.setDeckId(deck.getId());
        card.setUserId(userId);
        card.setFront(request.getFront());
        card.setBack(request.getBack());
        card = cardRepository.save(card);
        return toCardResponse(card, todayFor(userId));
    }

    @Transactional
    public CardResponse updateCard(UUID userId, UUID cardId, CardUpdateRequest request) {
        Card card = cardRepository.findByIdAndUserId(cardId, userId)
                .orElseThrow(() -> new BusinessException(404, "card.notfound"));
        card.setFront(request.getFront());
        card.setBack(request.getBack());
        card = cardRepository.save(card);
        return toCardResponse(card, todayFor(userId));
    }

    public CardResponse getCard(UUID userId, UUID cardId) {
        return toCardResponse(getCardForUser(userId, cardId), todayFor(userId));
    }

    @Transactional
    public void deleteCard(UUID userId, UUID cardId) {
        Card card = cardRepository.findByIdAndUserId(cardId, userId)
                .orElseThrow(() -> new BusinessException(404, "card.notfound"));
        cardRepository.delete(card);
    }

    @Transactional
    public int deleteCards(UUID userId, List<UUID> cardIds) {
        if (cardIds == null || cardIds.isEmpty()) {
            throw new BusinessException(400, "card.id.list.empty");
        }
        List<Card> ownedCards = cardRepository.findByIdInAndUserId(cardIds, userId);
        cardRepository.deleteAll(ownedCards);
        return ownedCards.size();
    }

    private static final int MAX_SEARCH_QUERY_LENGTH = 100;

    private String normalizeSearchQuery(String query) {
        if (query == null) return "";
        String trimmed = query.trim();
        if (trimmed.length() > MAX_SEARCH_QUERY_LENGTH) {
            throw new BusinessException(400, "card.search.too.long");
        }
        return trimmed;
    }

    private String searchPattern(String query) {
        String escaped = query
                .replace("\\", "\\\\")
                .replace("%", "\\%")
                .replace("_", "\\_");
        return "%" + escaped + "%";
    }

    public Card getCardForUser(UUID userId, UUID cardId) {
        return cardRepository.findByIdAndUserId(cardId, userId)
                .orElseThrow(() -> new BusinessException(404, "card.notfound"));
    }

    private CardResponse toCardResponse(Card card, LocalDate today) {
        SchedulingState s = card.getSchedulingState();
        boolean due = s.getNextReviewDate() != null && !s.getNextReviewDate().isAfter(today);
        return new CardResponse(
                card.getId(), card.getDeckId(), card.getFront(), card.getBack(),
                s.getStage(), s.getNextReviewDate(), s.isLearningMode(),
                s.getConsecutiveFamiliar(), s.getLearningStep(),
                s.getReentryStage(), due, card.getCreatedAt(),
                card.getReviewVersion(), s.getLearningOrigin());
    }

    private LocalDate todayFor(UUID userId) {
        LocalTime refreshTime = userRepository.findById(userId)
                .map(User::getRefreshTime)
                .orElse(LocalTime.of(4, 0));
        return DateUtils.calculateToday(refreshTime);
    }
}
