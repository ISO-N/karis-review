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

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
public class CardImportService {

    private final DeckRepository deckRepository;
    private final CardRepository cardRepository;
    private final CardImportParser cardImportParser;

    public CardImportService(DeckRepository deckRepository,
                             CardRepository cardRepository,
                             CardImportParser cardImportParser) {
        this.deckRepository = deckRepository;
        this.cardRepository = cardRepository;
        this.cardImportParser = cardImportParser;
    }

    public CardImportPreviewResponse preview(UUID userId, UUID deckId, String content) {
        requireDeck(userId, deckId);
        return cardImportParser.parse(content);
    }

    @Transactional
    public CardImportResult importCards(UUID userId, UUID deckId, CardImportRequest request) {
        Deck deck = requireDeck(userId, deckId);
        if (request == null || request.getCards() == null || request.getCards().isEmpty()) {
            throw new BusinessException(400, "卡片列表不能为空");
        }
        if (request.getCards().size() > CardImportParser.MAX_CARDS) {
            throw new BusinessException(400, "单次最多导入 " + CardImportParser.MAX_CARDS + " 张卡片");
        }

        List<Card> cards = new ArrayList<>(request.getCards().size());
        for (CardImportItem item : request.getCards()) {
            if (item == null) {
                throw new BusinessException(400, "卡片数据不能为空");
            }
            String front = requireText(item.getFront(), "正面内容不能为空");
            String back = requireText(item.getBack(), "反面内容不能为空");

            Card card = new Card();
            card.setDeckId(deck.getId());
            card.setUserId(userId);
            card.setFront(front);
            card.setBack(back);
            cards.add(card);
        }

        cardRepository.saveAll(cards);
        return new CardImportResult(cards.size());
    }

    private Deck requireDeck(UUID userId, UUID deckId) {
        return deckRepository.findByIdAndUserId(deckId, userId)
                .orElseThrow(() -> new BusinessException(404, "牌组不存在"));
    }

    private String requireText(String value, String message) {
        if (value == null || value.trim().isEmpty()) {
            throw new BusinessException(400, message);
        }
        return value;
    }
}
