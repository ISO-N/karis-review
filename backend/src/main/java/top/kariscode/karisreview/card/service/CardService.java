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
import top.kariscode.karisreview.deck.entity.Deck;
import top.kariscode.karisreview.deck.repository.DeckRepository;

import java.util.UUID;

@Service
public class CardService {

    private final CardRepository cardRepository;
    private final DeckRepository deckRepository;

    public CardService(CardRepository cardRepository, DeckRepository deckRepository) {
        this.cardRepository = cardRepository;
        this.deckRepository = deckRepository;
    }

    public Page<CardResponse> getDeckCards(UUID userId, UUID deckId, int page, int size) {
        // Verify deck belongs to user
        if (!deckRepository.existsByIdAndUserId(deckId, userId)) {
            throw new BusinessException(404, "牌组不存在");
        }

        return cardRepository.findByDeckIdOrderByCreatedAtAsc(deckId, PageRequest.of(page, size))
                .map(this::toCardResponse);
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
        // Stage 0 by default, no next_review_date (learning mode)
        card = cardRepository.save(card);
        return toCardResponse(card);
    }

    @Transactional
    public CardResponse updateCard(UUID userId, UUID cardId, CardUpdateRequest request) {
        Card card = cardRepository.findByIdAndUserId(cardId, userId)
                .orElseThrow(() -> new BusinessException(404, "卡片不存在"));
        card.setFront(request.getFront());
        card.setBack(request.getBack());
        card = cardRepository.save(card);
        return toCardResponse(card);
    }
    public CardResponse getCard(UUID userId, UUID cardId) {
        return toCardResponse(getCardForUser(userId, cardId));
    }

    @Transactional
    public void deleteCard(UUID userId, UUID cardId) {
        Card card = cardRepository.findByIdAndUserId(cardId, userId)
                .orElseThrow(() -> new BusinessException(404, "卡片不存在"));
        cardRepository.delete(card);
    }

    public Card getCardForUser(UUID userId, UUID cardId) {
        return cardRepository.findByIdAndUserId(cardId, userId)
                .orElseThrow(() -> new BusinessException(404, "卡片不存在"));
    }

    private CardResponse toCardResponse(Card card) {
        return new CardResponse(
                card.getId(), card.getFront(), card.getBack(),
                card.getStage(), card.getNextReviewDate(),
                card.isLearningMode(), card.getCreatedAt());
    }
}