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

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
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
        LocalTime refreshTime = getRefreshTime(userId);
        return toDeckResponse(deck, refreshTime);
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
        LocalDate today = DateUtils.calculateToday(refreshTime);
        UUID deckId = deck.getId();
        int cardCount = (int) cardRepository.countByDeckId(deckId);
        int dueCount = cardRepository.countDueByDeckId(deckId, today);
        int newCount = (int) cardRepository.countByDeckIdAndStageAndLearningModeFalse(deckId, 0);
        int masteredCount = (int) cardRepository.countByDeckIdAndStageGreaterThanEqual(deckId, 5);
        Map<String, Long> stageDistribution = distributionFromRows(
                cardRepository.countByStageGroupedByDeck(deckId));
        Map<String, Long> dueStageDistribution = distributionFromRows(
                cardRepository.countDueByStageGroupedByDeck(deckId, today));
        return new DeckResponse(deck.getId(), deck.getName(), cardCount, dueCount,
                newCount, masteredCount, stageDistribution, dueStageDistribution,
                deck.getCreatedAt());
    }

    private Map<String, Long> distributionFromRows(List<Object[]> rows) {
        Map<String, Long> distribution = new LinkedHashMap<>();
        for (int i = 0; i <= 8; i++) {
            distribution.put(String.valueOf(i), 0L);
        }
        for (Object[] row : rows) {
            String stage = String.valueOf(((Number) row[0]).intValue());
            distribution.merge(stage, ((Number) row[1]).longValue(), Long::sum);
        }
        return distribution;
    }

    private LocalTime getRefreshTime(UUID userId) {
        return userRepository.findById(userId)
                .map(User::getRefreshTime)
                .orElse(LocalTime.of(4, 0));
    }
}
