package top.kariscode.karisreview.sync.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import top.kariscode.karisreview.auth.entity.User;
import top.kariscode.karisreview.auth.repository.UserRepository;
import top.kariscode.karisreview.card.entity.Card;
import top.kariscode.karisreview.card.repository.CardRepository;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.deck.entity.Deck;
import top.kariscode.karisreview.deck.repository.DeckRepository;
import top.kariscode.karisreview.review.entity.ReviewLog;
import top.kariscode.karisreview.review.repository.ReviewLogRepository;
import top.kariscode.karisreview.sync.dto.BootstrapCard;
import top.kariscode.karisreview.sync.dto.BootstrapDeck;
import top.kariscode.karisreview.sync.dto.BootstrapResponse;
import top.kariscode.karisreview.sync.dto.BootstrapReviewLog;
import top.kariscode.karisreview.sync.dto.BootstrapUser;

import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;

@Service
public class SyncService {

    private final UserRepository userRepository;
    private final DeckRepository deckRepository;
    private final CardRepository cardRepository;
    private final ReviewLogRepository reviewLogRepository;

    public SyncService(UserRepository userRepository,
                       DeckRepository deckRepository,
                       CardRepository cardRepository,
                       ReviewLogRepository reviewLogRepository) {
        this.userRepository = userRepository;
        this.deckRepository = deckRepository;
        this.cardRepository = cardRepository;
        this.reviewLogRepository = reviewLogRepository;
    }

    @Transactional(readOnly = true)
    public BootstrapResponse getBootstrap(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(404, "用户不存在"));

        List<Deck> decks = deckRepository.findByUserIdOrderByCreatedAtAsc(userId);
        List<BootstrapDeck> deckResponses = decks.stream()
                .map(deck -> new BootstrapDeck(
                        deck.getId(), deck.getName(), deck.getCreatedAt(), deck.getUpdatedAt(),
                        cardsForDeck(deck.getId())))
                .toList();

        List<BootstrapReviewLog> logResponses = reviewLogRepository
                .findByUserIdOrderByReviewedAtDesc(userId)
                .stream()
                .map(this::toBootstrapLog)
                .toList();

        String refreshTime = user.getRefreshTime().format(DateTimeFormatter.ofPattern("HH:mm:ss"));
        return new BootstrapResponse(
                OffsetDateTime.now(ZoneOffset.UTC),
                new BootstrapUser(user.getId(), user.getEmail(), refreshTime),
                deckResponses,
                logResponses);
    }

    private List<BootstrapCard> cardsForDeck(UUID deckId) {
        return cardRepository.findByDeckIdOrderByCreatedAtAsc(deckId)
                .stream()
                .map(this::toBootstrapCard)
                .toList();
    }

    private BootstrapCard toBootstrapCard(Card card) {
        return new BootstrapCard(
                card.getId(), card.getDeckId(), card.getFront(), card.getBack(),
                card.getStage(), card.getConsecutiveFamiliar(), card.getNextReviewDate(),
                card.isLearningMode(), card.getReentryStage(), card.getLearningStep(),
                card.getReviewVersion(), card.getCreatedAt(), card.getUpdatedAt());
    }

    private BootstrapReviewLog toBootstrapLog(ReviewLog log) {
        return new BootstrapReviewLog(
                log.getId(), log.getCardId(), log.getRating(),
                log.getStageBefore(), log.getStageAfter(), log.getReviewedAt());
    }
}
