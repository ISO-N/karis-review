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
import top.kariscode.karisreview.sync.repository.SyncEventRepository;

import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
public class SyncService {

    private static final int DELTA_PAGE_SIZE = 500;

    private final UserRepository userRepository;
    private final DeckRepository deckRepository;
    private final CardRepository cardRepository;
    private final ReviewLogRepository reviewLogRepository;
    private final SyncEventRepository syncEventRepository;

    public SyncService(UserRepository userRepository,
                       DeckRepository deckRepository,
                       CardRepository cardRepository,
                       ReviewLogRepository reviewLogRepository,
                       SyncEventRepository syncEventRepository) {
        this.userRepository = userRepository;
        this.deckRepository = deckRepository;
        this.cardRepository = cardRepository;
        this.reviewLogRepository = reviewLogRepository;
        this.syncEventRepository = syncEventRepository;
    }

    @Transactional(readOnly = true)
    public BootstrapResponse getBootstrap(UUID userId) {
        return getBootstrap(userId, 0);
    }

    @Transactional(readOnly = true)
    public BootstrapResponse getBootstrap(UUID userId, long eventCursor) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(404, "sync.user.notfound"));
        OffsetDateTime serverTime = OffsetDateTime.now(ZoneOffset.UTC);

        if (eventCursor <= 0) {
            return fullBootstrap(user, serverTime);
        }
        return deltaBootstrap(user, serverTime, eventCursor);
    }

    private BootstrapResponse fullBootstrap(User user, OffsetDateTime serverTime) {
        List<Deck> decks = deckRepository.findByUserIdOrderByCreatedAtAsc(user.getId());
        List<BootstrapDeck> deckResponses = decks.stream()
                .map(deck -> new BootstrapDeck(
                        deck.getId(), deck.getName(), deck.getCreatedAt(), deck.getUpdatedAt(),
                        cardsForDeck(deck.getId())))
                .toList();

        List<BootstrapReviewLog> logResponses = reviewLogRepository
                .findByUserIdOrderByReviewedAtDesc(user.getId())
                .stream()
                .map(this::toBootstrapLog)
                .toList();

        return new BootstrapResponse(
                serverTime,
                toBootstrapUser(user),
                deckResponses,
                logResponses,
                List.of(),
                List.of(),
                List.of(),
                List.of(),
                syncEventRepository.latestSeq(user.getId()),
                false, false);
    }

    private BootstrapResponse deltaBootstrap(User user, OffsetDateTime serverTime, long cursor) {
        long latestSeq = syncEventRepository.latestSeq(user.getId());
        if (cursor > latestSeq) {
            return new BootstrapResponse(
                    serverTime, toBootstrapUser(user), List.of(), List.of(),
                    List.of(), List.of(), List.of(), List.of(),
                    latestSeq, false, true);
        }

        List<SyncEventRepository.SyncEventRow> events =
                syncEventRepository.findAfter(user.getId(), cursor, DELTA_PAGE_SIZE);

        if (events.isEmpty()) {
            return new BootstrapResponse(
                    serverTime, toBootstrapUser(user), List.of(), List.of(),
                    List.of(), List.of(), List.of(), List.of(),
                    latestSeq, false, false);
        }

        Set<UUID> deckIds = new HashSet<>();
        Set<UUID> cardIds = new HashSet<>();
        Set<UUID> reviewLogIds = new HashSet<>();
        List<String> deletedDeckIds = new ArrayList<>();
        List<String> deletedCardIds = new ArrayList<>();
        List<String> deletedReviewLogIds = new ArrayList<>();

        for (SyncEventRepository.SyncEventRow event : events) {
            switch (event.entityType()) {
                case "decks" -> {
                    if ("DELETED".equals(event.eventType())) {
                        deletedDeckIds.add(event.entityId().toString());
                    } else {
                        deckIds.add(event.entityId());
                    }
                }
                case "cards" -> {
                    if ("DELETED".equals(event.eventType())) {
                        deletedCardIds.add(event.entityId().toString());
                    } else {
                        cardIds.add(event.entityId());
                    }
                }
                case "review_logs" -> {
                    if ("DELETED".equals(event.eventType())) {
                        deletedReviewLogIds.add(event.entityId().toString());
                    } else {
                        reviewLogIds.add(event.entityId());
                    }
                }
                default -> {
                    // users 事件不携带额外业务载荷，user 每次都会随响应返回。
                }
            }
        }

        List<BootstrapDeck> changedDecks = deckIds.stream()
                .map(id -> deckRepository.findByIdAndUserId(id, user.getId()))
                .filter(java.util.Optional::isPresent)
                .map(java.util.Optional::get)
                .map(deck -> new BootstrapDeck(
                        deck.getId(), deck.getName(), deck.getCreatedAt(),
                        deck.getUpdatedAt(), List.of()))
                .toList();

        List<BootstrapCard> changedCards = cardRepository.findAllById(cardIds).stream()
                .filter(card -> user.getId().equals(card.getUserId()))
                .map(this::toBootstrapCard)
                .toList();

        List<BootstrapReviewLog> newLogs = reviewLogRepository.findAllById(reviewLogIds).stream()
                .filter(log -> user.getId().equals(log.getUserId()))
                .map(this::toBootstrapLog)
                .toList();

        long lastSeq = events.get(events.size() - 1).eventSeq();
        boolean hasMore = events.size() >= DELTA_PAGE_SIZE;

        return new BootstrapResponse(
                serverTime, toBootstrapUser(user), changedDecks, newLogs,
                changedCards, deletedDeckIds, deletedCardIds, deletedReviewLogIds,
                lastSeq, hasMore, false);
    }

    private List<BootstrapCard> cardsForDeck(UUID deckId) {
        return cardRepository.findByDeckIdOrderByCreatedAtAsc(deckId)
                .stream()
                .map(this::toBootstrapCard)
                .toList();
    }

    private BootstrapUser toBootstrapUser(User user) {
        return new BootstrapUser(
                user.getId(),
                user.getEmail(),
                user.getRefreshTime().format(DateTimeFormatter.ofPattern("HH:mm:ss")));
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
                log.getStageBefore(), log.getStageAfter(), log.getReviewedAt(),
                log.isNewCard(), log.getClientRequestId());
    }
}
