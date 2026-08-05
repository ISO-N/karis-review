package top.kariscode.karisreview.sync.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import top.kariscode.karisreview.auth.api.IdentityPort;
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

import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class SyncService {

    private static final Logger log = LoggerFactory.getLogger(SyncService.class);

    private static final int DELTA_PAGE_SIZE = 500;
    /** sync_events 保留天数：超过该时限的事件允许被清理（与 V13 迁移一致）。 */
    private static final int SYNC_EVENT_RETENTION_DAYS = 60;

    private final IdentityPort identityPort;
    private final DeckRepository deckRepository;
    private final CardRepository cardRepository;
    private final ReviewLogRepository reviewLogRepository;
    private final SyncEventRepository syncEventRepository;

    public SyncService(IdentityPort identityPort,
                       DeckRepository deckRepository,
                       CardRepository cardRepository,
                       ReviewLogRepository reviewLogRepository,
                       SyncEventRepository syncEventRepository) {
        this.identityPort = identityPort;
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
        IdentityPort.UserView user = identityPort.findById(userId)
                .orElseThrow(() -> new BusinessException(404, "sync.user.notfound"));
        OffsetDateTime serverTime = OffsetDateTime.now(ZoneOffset.UTC);

        if (eventCursor <= 0) {
            return fullBootstrap(user, serverTime);
        }
        return deltaBootstrap(user, serverTime, eventCursor);
    }

    /**
     * 定期清理过期 sync_events（每天 03:30，与 user_logs 的 03:00 错开）。
     * 清理后旧客户端游标失效时，deltaBootstrap 的 minSeq/latestSeq 检查
     * 会自动降级为全量同步，不影响增量一致性。
     */
    @Scheduled(cron = "0 30 3 * * *")
    @Transactional
    public void cleanupOldSyncEvents() {
        LocalDateTime cutoff = LocalDateTime.now().minusDays(SYNC_EVENT_RETENTION_DAYS);
        int deleted = syncEventRepository.deleteOlderThan(cutoff);
        if (deleted > 0) {
            log.info("Cleaned up {} sync_events older than {}", deleted, cutoff);
        }
    }

    private BootstrapResponse fullBootstrap(IdentityPort.UserView user, OffsetDateTime serverTime) {
        List<Deck> decks = deckRepository.findByUserIdOrderByCreatedAtAsc(user.id());

        // 一次取出该用户全部卡片并按卡组分组，替代逐卡组查询（N+1）
        Map<UUID, List<Card>> cardsByDeck = cardRepository.findByUserId(user.id()).stream()
                .collect(Collectors.groupingBy(Card::getDeckId));
        List<BootstrapDeck> deckResponses = decks.stream()
                .map(deck -> new BootstrapDeck(
                        deck.getId(), deck.getName(), deck.getCreatedAt(), deck.getUpdatedAt(),
                        cardsForDeck(cardsByDeck, deck.getId())))
                .toList();

        // 复习日志分批拉取，避免一次性拖出上万行（行为不变，仍返回全量）
        List<BootstrapReviewLog> logResponses = new ArrayList<>();
        int page = 0;
        while (true) {
            Page<ReviewLog> logPage = reviewLogRepository.findByUserIdOrderByReviewedAtDesc(
                    user.id(), PageRequest.of(page, DELTA_PAGE_SIZE));
            if (!logPage.hasContent()) {
                break;
            }
            logPage.getContent().stream().map(this::toBootstrapLog).forEach(logResponses::add);
            if (!logPage.hasNext()) {
                break;
            }
            page++;
        }

        return new BootstrapResponse(
                serverTime,
                toBootstrapUser(user),
                deckResponses,
                logResponses,
                List.of(),
                List.of(),
                List.of(),
                List.of(),
                syncEventRepository.latestSeq(user.id()),
                false, false);
    }

    private BootstrapResponse deltaBootstrap(IdentityPort.UserView user, OffsetDateTime serverTime, long cursor) {
        long latestSeq = syncEventRepository.latestSeq(user.id());
        if (cursor > latestSeq) {
            return new BootstrapResponse(
                    serverTime, toBootstrapUser(user), List.of(), List.of(),
                    List.of(), List.of(), List.of(), List.of(),
                    latestSeq, false, true);
        }

        // 游标已过期：要么事件被清理（cursor < 最早保留事件），要么事件被整体清空
        // （latestSeq == 0 但客户端已有游标），此时增量无法继续，降级为全量同步。
        long minSeq = syncEventRepository.minSeq(user.id());
        if (cursor < minSeq || latestSeq == 0) {
            return fullBootstrap(user, serverTime);
        }
        List<SyncEventRepository.SyncEventRow> events =
                syncEventRepository.findAfter(user.id(), cursor, DELTA_PAGE_SIZE);

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
                .map(id -> deckRepository.findByIdAndUserId(id, user.id()))
                .filter(java.util.Optional::isPresent)
                .map(java.util.Optional::get)
                .map(deck -> new BootstrapDeck(
                        deck.getId(), deck.getName(), deck.getCreatedAt(),
                        deck.getUpdatedAt(), List.of()))
                .toList();

        List<BootstrapCard> changedCards = cardRepository.findAllById(cardIds).stream()
                .filter(card -> user.id().equals(card.getUserId()))
                .map(this::toBootstrapCard)
                .toList();

        List<BootstrapReviewLog> newLogs = reviewLogRepository.findAllById(reviewLogIds).stream()
                .filter(log -> user.id().equals(log.getUserId()))
                .map(this::toBootstrapLog)
                .toList();

        long lastSeq = events.get(events.size() - 1).eventSeq();
        boolean hasMore = events.size() >= DELTA_PAGE_SIZE;

        return new BootstrapResponse(
                serverTime, toBootstrapUser(user), changedDecks, newLogs,
                changedCards, deletedDeckIds, deletedCardIds, deletedReviewLogIds,
                lastSeq, hasMore, false);
    }

    private List<BootstrapCard> cardsForDeck(Map<UUID, List<Card>> cardsByDeck, UUID deckId) {
        return cardsByDeck.getOrDefault(deckId, List.of()).stream()
                .map(this::toBootstrapCard)
                .toList();
    }

    private BootstrapUser toBootstrapUser(IdentityPort.UserView user) {
        return new BootstrapUser(
                user.id(),
                user.email(),
                user.refreshTime().format(DateTimeFormatter.ofPattern("HH:mm:ss")));
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
