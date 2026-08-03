package top.kariscode.karisreview.card.service;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import top.kariscode.karisreview.card.dto.CardCreateRequest;
import top.kariscode.karisreview.card.dto.CardResponse;
import top.kariscode.karisreview.card.dto.CardUpdateRequest;
import top.kariscode.karisreview.card.entity.Card;
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
        if (!deckRepository.existsByIdAndUserId(deckId, userId)) {
            throw new BusinessException(404, "牌组不存在");
        }

        PageRequest pageRequest = PageRequest.of(page, size);
        LocalDate today = todayFor(userId);
        Page<Card> cards = switch (filter == null ? "all" : filter) {
            case "due" -> cardRepository
                    .findByDeckIdAndNextReviewDateNotNullAndNextReviewDateLessThanEqualOrderByNextReviewDateAsc(
                            deckId, today, pageRequest);
            case "learning" -> cardRepository
                    .findByDeckIdAndLearningModeTrueOrderByCreatedAtAsc(deckId, pageRequest);
            case "new" -> cardRepository.findNewByDeckIdOrderByCreatedAtDesc(deckId, pageRequest);
            default -> cardRepository.findByDeckIdOrderByCreatedAtAsc(deckId, pageRequest);
        };
        return cards.map(card -> toCardResponse(card, today));
    }

    @Transactional
    public CardResponse createCard(UUID userId, UUID deckId, CardCreateRequest request) {
        Deck deck = deckRepository.findByIdAndUserId(deckId, userId)
                .orElseThrow(() -> new BusinessException(404, "牌组不存在"));

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
                .orElseThrow(() -> new BusinessException(404, "卡片不存在"));
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
                .orElseThrow(() -> new BusinessException(404, "卡片不存在"));
        cardRepository.delete(card);
    }

    @Transactional
    public int deleteCards(UUID userId, List<UUID> cardIds) {
        if (cardIds == null || cardIds.isEmpty()) {
            throw new BusinessException(400, "卡片 ID 列表不能为空");
        }
        List<Card> ownedCards = cardRepository.findByIdInAndUserId(cardIds, userId);
        cardRepository.deleteAll(ownedCards);
        return ownedCards.size();
    }

    public Card getCardForUser(UUID userId, UUID cardId) {
        return cardRepository.findByIdAndUserId(cardId, userId)
                .orElseThrow(() -> new BusinessException(404, "卡片不存在"));
    }

    private CardResponse toCardResponse(Card card, LocalDate today) {
        boolean due = card.getNextReviewDate() != null && !card.getNextReviewDate().isAfter(today);
        return new CardResponse(
                card.getId(), card.getDeckId(), card.getFront(), card.getBack(),
                card.getStage(), card.getNextReviewDate(), card.isLearningMode(),
                card.getConsecutiveFamiliar(), card.getLearningStep(),
                card.getReentryStage(), due, card.getCreatedAt(),
                card.getReviewVersion());
    }

    private LocalDate todayFor(UUID userId) {
        LocalTime refreshTime = userRepository.findById(userId)
                .map(User::getRefreshTime)
                .orElse(LocalTime.of(4, 0));
        return DateUtils.calculateToday(refreshTime);
    }
}
