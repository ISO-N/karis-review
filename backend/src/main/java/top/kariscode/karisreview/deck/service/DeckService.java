package top.kariscode.karisreview.deck.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.deck.dto.DeckCreateRequest;
import top.kariscode.karisreview.deck.dto.DeckResponse;
import top.kariscode.karisreview.deck.dto.DeckUpdateRequest;
import top.kariscode.karisreview.deck.entity.Deck;
import top.kariscode.karisreview.deck.repository.DeckRepository;
import top.kariscode.karisreview.stats.dto.DeckCounters;
import top.kariscode.karisreview.stats.service.StatsService;

import java.util.List;
import java.util.UUID;

@Service
public class DeckService {

    private final DeckRepository deckRepository;
    private final StatsService statsService;

    public DeckService(DeckRepository deckRepository,
                       StatsService statsService) {
        this.deckRepository = deckRepository;
        this.statsService = statsService;
    }

    public List<DeckResponse> getUserDecks(UUID userId) {
        return deckRepository.findByUserIdOrderByCreatedAtAsc(userId).stream()
                .map(deck -> toDeckResponse(userId, deck))
                .toList();
    }

    @Transactional
    public DeckResponse createDeck(UUID userId, DeckCreateRequest request) {
        Deck deck = new Deck();
        deck.setUserId(userId);
        deck.setName(request.getName());
        deck = deckRepository.save(deck);
        return toDeckResponse(userId, deck);
    }

    @Transactional
    public DeckResponse updateDeck(UUID userId, UUID deckId, DeckUpdateRequest request) {
        Deck deck = deckRepository.findByIdAndUserId(deckId, userId)
                .orElseThrow(() -> new BusinessException(404, "deck.notfound"));
        deck.setName(request.getName());
        deck = deckRepository.save(deck);
        return toDeckResponse(userId, deck);
    }

    @Transactional
    public void deleteDeck(UUID userId, UUID deckId) {
        Deck deck = deckRepository.findByIdAndUserId(deckId, userId)
                .orElseThrow(() -> new BusinessException(404, "deck.notfound"));
        deckRepository.delete(deck);
    }

    public Deck getDeckForUser(UUID userId, UUID deckId) {
        return deckRepository.findByIdAndUserId(deckId, userId)
                .orElseThrow(() -> new BusinessException(404, "deck.notfound"));
    }

    // 卡组计数统一经 StatsService.getDeckCounters（架构评审候选 4）——
    // 曾在本类重复实现 6 项计数与 distributionFromRows。
    private DeckResponse toDeckResponse(UUID userId, Deck deck) {
        DeckCounters counters = statsService.getDeckCounters(userId, deck.getId());
        return new DeckResponse(deck.getId(), deck.getName(), counters.getCardCount(),
                counters.getDueCount(), counters.getNewCount(), counters.getMasteredCount(),
                counters.getStageDistribution(), counters.getDueStageDistribution(),
                deck.getCreatedAt());
    }
}
