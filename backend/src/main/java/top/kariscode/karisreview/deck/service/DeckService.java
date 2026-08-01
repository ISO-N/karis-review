package top.kariscode.karisreview.deck.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import top.kariscode.karisreview.card.repository.CardRepository;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.common.util.DateUtils;
import top.kariscode.karisreview.deck.dto.DeckCreateRequest;
import top.kariscode.karisreview.deck.dto.DeckResponse;
import top.kariscode.karisreview.deck.dto.DeckUpdateRequest;
import top.kariscode.karisreview.deck.entity.Deck;
import top.kariscode.karisreview.deck.repository.DeckRepository;
import top.kariscode.karisreview.auth.entity.User;
import top.kariscode.karisreview.auth.repository.UserRepository;

import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

@Service
public class DeckService {

    private final DeckRepository deckRepository;
    private final CardRepository cardRepository;
    private final UserRepository userRepository;

    public DeckService(DeckRepository deckRepository,
                       CardRepository cardRepository,
                       UserRepository userRepository) {
        this.deckRepository = deckRepository;
        this.cardRepository = cardRepository;
        this.userRepository = userRepository;
    }

    public List<DeckResponse> getUserDecks(UUID userId) {
        LocalTime refreshTime = getRefreshTime(userId);
        return deckRepository.findByUserIdOrderByCreatedAtAsc(userId).stream()
                .map(deck -> toDeckResponse(deck, refreshTime))
                .toList();
    }

    @Transactional
    public DeckResponse createDeck(UUID userId, DeckCreateRequest request) {
        Deck deck = new Deck();
        deck.setUserId(userId);
        deck.setName(request.getName());
        deck = deckRepository.save(deck);
        return new DeckResponse(deck.getId(), deck.getName(), 0, 0, deck.getCreatedAt());
    }

    @Transactional
    public DeckResponse updateDeck(UUID userId, UUID deckId, DeckUpdateRequest request) {
        Deck deck = deckRepository.findByIdAndUserId(deckId, userId)
                .orElseThrow(() -> new BusinessException(404, "牌组不存在"));
        deck.setName(request.getName());
        deck = deckRepository.save(deck);
        LocalTime refreshTime = getRefreshTime(userId);
        return toDeckResponse(deck, refreshTime);
    }

    @Transactional
    public void deleteDeck(UUID userId, UUID deckId) {
        Deck deck = deckRepository.findByIdAndUserId(deckId, userId)
                .orElseThrow(() -> new BusinessException(404, "牌组不存在"));
        deckRepository.delete(deck);
    }

    public Deck getDeckForUser(UUID userId, UUID deckId) {
        return deckRepository.findByIdAndUserId(deckId, userId)
                .orElseThrow(() -> new BusinessException(404, "牌组不存在"));
    }

    private DeckResponse toDeckResponse(Deck deck, LocalTime refreshTime) {
        int cardCount = (int) cardRepository.countByDeckId(deck.getId());
        int dueCount = cardRepository.countDueByDeckId(deck.getId(), DateUtils.calculateToday(refreshTime));
        return new DeckResponse(deck.getId(), deck.getName(), cardCount, dueCount, deck.getCreatedAt());
    }

    private LocalTime getRefreshTime(UUID userId) {
        return userRepository.findById(userId)
                .map(User::getRefreshTime)
                .orElse(LocalTime.of(4, 0));
    }
}