package top.kariscode.karisreview.card.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import top.kariscode.karisreview.card.dto.CardImportItem;
import top.kariscode.karisreview.card.dto.CardImportPreviewResponse;
import top.kariscode.karisreview.card.dto.CardImportRequest;
import top.kariscode.karisreview.card.dto.CardImportResult;
import top.kariscode.karisreview.card.entity.Card;
import top.kariscode.karisreview.card.repository.CardRepository;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.deck.entity.Deck;
import top.kariscode.karisreview.deck.repository.DeckRepository;
import top.kariscode.karisreview.log.service.UserLogService;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
public class CardImportService {

    private final DeckRepository deckRepository;
    private final CardRepository cardRepository;
    private final CardImportParser cardImportParser;
    private final UserLogService userLogService;

    public CardImportService(DeckRepository deckRepository,
                             CardRepository cardRepository,
                             CardImportParser cardImportParser,
                             UserLogService userLogService) {
        this.deckRepository = deckRepository;
        this.cardRepository = cardRepository;
        this.cardImportParser = cardImportParser;
        this.userLogService = userLogService;
    }

    public CardImportPreviewResponse preview(UUID userId, UUID deckId, String content) {
        requireDeck(userId, deckId);
        return cardImportParser.parse(content);
    }

    @Transactional
    public CardImportResult importCards(UUID userId, UUID deckId, CardImportRequest request) {
        Deck deck = requireDeck(userId, deckId);
        if (request == null || request.getCards() == null || request.getCards().isEmpty()) {
            throw new BusinessException(400, "card.import.list.empty");
        }
        if (request.getCards().size() > CardImportParser.MAX_CARDS) {
            throw new BusinessException(400, "card.import.too.many", CardImportParser.MAX_CARDS);
        }

        List<Card> cards = new ArrayList<>(request.getCards().size());
        for (CardImportItem item : request.getCards()) {
            if (item == null) {
                throw new BusinessException(400, "card.import.data.empty");
            }
            String front = requireText(item.getFront(), "card.import.front.empty");
            String back = requireText(item.getBack(), "card.import.back.empty");
            Card card = new Card();
            card.setDeckId(deck.getId());
            card.setUserId(userId);
            card.setFront(front);
            card.setBack(back);
            cards.add(card);
        }

        List<Card> savedCards = cardRepository.saveAll(cards);
        List<UUID> importedCardIds = savedCards.stream()
                .map(Card::getId)
                .toList();
        userLogService.log(userId, "INFO", "CARD",
                "Imported " + savedCards.size() + " card(s) into deck");
        return new CardImportResult(savedCards.size(), importedCardIds);
    }

    private Deck requireDeck(UUID userId, UUID deckId) {
        return deckRepository.findByIdAndUserId(deckId, userId)
                .orElseThrow(() -> new BusinessException(404, "deck.notfound"));
    }

    private String requireText(String value, String message) {
        if (value == null || value.trim().isEmpty()) {
            throw new BusinessException(400, message);
        }
        return value;
    }
}