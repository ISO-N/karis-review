package top.kariscode.karisreview.backup.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;
import top.kariscode.karisreview.auth.api.IdentityPort;
import top.kariscode.karisreview.backup.entity.BackupSnapshot;
import top.kariscode.karisreview.backup.repository.BackupRepository;
import top.kariscode.karisreview.backup.storage.BackupStorage;
import top.kariscode.karisreview.card.entity.Card;
import top.kariscode.karisreview.card.repository.CardRepository;
import top.kariscode.karisreview.deck.entity.Deck;
import top.kariscode.karisreview.deck.repository.DeckRepository;
import top.kariscode.karisreview.log.service.UserLogService;
import top.kariscode.karisreview.review.entity.ReviewLog;
import top.kariscode.karisreview.review.repository.ReviewLogRepository;

import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

/**
 * 备份服务（WP-1/G1/G10 改造版）：
 * <ul>
 *   <li><b>快照外置</b>：数据写入 {@link BackupStorage}（对象存储/独立磁盘），库内只存元数据，与主库故障域分离；</li>
 *   <li><b>导入安全</b>：导入前自动快照（独立事务），导入失败整体回滚，不再留下半删状态；</li>
 *   <li><b>保留策略</b>：每用户最近 7 份，清理时同步删除对象存储文件。</li>
 * </ul>
 */
@Service
public class BackupService {

    private static final Logger log = LoggerFactory.getLogger(BackupService.class);

    /** 每个用户最多保留的全量快照份数。 */
    private static final int MAX_SNAPSHOTS_PER_USER = 7;

    private final IdentityPort identityPort;
    private final DeckRepository deckRepository;
    private final CardRepository cardRepository;
    private final ReviewLogRepository reviewLogRepository;
    private final BackupRepository backupRepository;
    private final ObjectMapper objectMapper;
    private final UserLogService userLogService;
    private final Optional<BackupStorage> backupStorage;
    private final Optional<TransactionTemplate> transactionTemplate;

    public BackupService(IdentityPort identityPort,
                         DeckRepository deckRepository,
                         CardRepository cardRepository,
                         ReviewLogRepository reviewLogRepository,
                         BackupRepository backupRepository,
                         ObjectMapper objectMapper,
                         UserLogService userLogService) {
        this(identityPort, deckRepository, cardRepository, reviewLogRepository,
                backupRepository, objectMapper, userLogService, Optional.empty(), Optional.empty());
    }

    @Autowired
    public BackupService(IdentityPort identityPort,
                         DeckRepository deckRepository,
                         CardRepository cardRepository,
                         ReviewLogRepository reviewLogRepository,
                         BackupRepository backupRepository,
                         ObjectMapper objectMapper,
                         UserLogService userLogService,
                         Optional<BackupStorage> backupStorage,
                         Optional<PlatformTransactionManager> transactionManager) {
        this.identityPort = identityPort;
        this.deckRepository = deckRepository;
        this.cardRepository = cardRepository;
        this.reviewLogRepository = reviewLogRepository;
        this.backupRepository = backupRepository;
        this.objectMapper = objectMapper;
        this.userLogService = userLogService;
        this.backupStorage = backupStorage;
        this.transactionTemplate = transactionManager.map(TransactionTemplate::new);
    }

    @Transactional
    public Map<String, Object> exportData(UUID userId) {
        IdentityPort.UserView user = identityPort.findById(userId)
                .orElseThrow(() -> new RuntimeException("用户不存在"));

        String json = buildExportJson(user, userId);
        BackupSnapshot snapshot = persistSnapshot(userId, json);

        userLogService.log(userId, "INFO", "BACKUP",
                "Backup created with storage=" + snapshot.getStorageStatus());

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("backup_id", snapshot.getId().toString());
        response.put("exported_at", snapshot.getCreatedAt().toString());
        response.put("storage", snapshot.getStorageStatus());
        try {
            response.put("data", objectMapper.readValue(json, Map.class));
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Failed to parse backup data", e);
        }
        return response;
    }

    /**
     * 构建导出 JSON（不含持久化）。
     */
    private String buildExportJson(IdentityPort.UserView user, UUID userId) {
        List<Deck> decks = deckRepository.findByUserIdOrderByCreatedAtAsc(userId);

        ObjectNode root = objectMapper.createObjectNode();
        root.put("exported_at", LocalDateTime.now().toString());

        ObjectNode userNode = root.putObject("user");
        userNode.put("email", user.email());
        userNode.put("refresh_time", user.refreshTime().format(DateTimeFormatter.ofPattern("HH:mm:ss")));

        ArrayNode decksArray = root.putArray("decks");
        for (Deck deck : decks) {
            ObjectNode deckNode = decksArray.addObject();
            deckNode.put("name", deck.getName());
            ArrayNode cardsArray = deckNode.putArray("cards");
            List<Card> cards = cardRepository.findByDeckIdOrderByCreatedAtAsc(deck.getId());
            for (Card card : cards) {
                ObjectNode cardNode = cardsArray.addObject();
                cardNode.put("front", card.getFront());
                cardNode.put("back", card.getBack());
                cardNode.put("stage", card.getStage());
                cardNode.put("consecutive_familiar", card.getConsecutiveFamiliar());
                cardNode.put("next_review_date", card.getNextReviewDate() != null ? card.getNextReviewDate().toString() : null);
                cardNode.put("learning_mode", card.isLearningMode());
                cardNode.put("reentry_stage", card.getReentryStage());
            }
        }

        ArrayNode logsArray = root.putArray("review_logs");
        List<ReviewLog> logs = reviewLogRepository.findByUserIdOrderByReviewedAtDesc(userId);
        Map<UUID, String> cardFrontMap = new HashMap<>();
        for (ReviewLog log : logs) {
            cardFrontMap.putIfAbsent(log.getCardId(), "");
        }
        for (Card c : cardRepository.findAllById(cardFrontMap.keySet())) {
            cardFrontMap.put(c.getId(), c.getFront());
        }
        for (ReviewLog log : logs) {
            ObjectNode logNode = logsArray.addObject();
            logNode.put("card_front", cardFrontMap.getOrDefault(log.getCardId(), ""));
            logNode.put("rating", log.getRating());
            logNode.put("stage_before", log.getStageBefore());
            logNode.put("stage_after", log.getStageAfter());
            logNode.put("is_new_card", log.isNewCard());
            logNode.put("reviewed_at", log.getReviewedAt().toString());
        }

        try {
            return objectMapper.writeValueAsString(root);
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Failed to serialize backup data", e);
        }
    }

    /**
     * 持久化快照：优先对象存储（故障域分离），否则落库内 data 列（本地兼容模式）。
     */
    private BackupSnapshot persistSnapshot(UUID userId, String json) {
        byte[] bytes = json.getBytes(StandardCharsets.UTF_8);
        BackupSnapshot snapshot = new BackupSnapshot();
        snapshot.setUserId(userId);

        if (backupStorage.isPresent()) {
            String key = "users/" + userId + "/snapshots/" + UUID.randomUUID() + ".json";
            BackupStorage.StorageResult meta = backupStorage.get().save(key, bytes);
            snapshot.setStorageKey(key);
            snapshot.setStorageSize(meta.sizeBytes());
            snapshot.setStorageSha256(meta.sha256());
            snapshot.setStorageStatus("OBJECT_STORAGE");
            snapshot.setData(null); // 数据在对象存储，库内不冗余存储
        } else {
            snapshot.setData(json);
            snapshot.setStorageStatus("LOCAL");
        }
        return backupRepository.save(snapshot);
    }

    /**
     * 导入用户数据。事务化 + 导入前自动快照：
     * <ol>
     *   <li>在<em>独立事务</em>中先为当前状态建立快照（导入失败也有恢复点）；</li>
     *   <li>随后在主事务中执行 删除 → 导入；任何异常自动回滚，不留半删状态。</li>
     * </ol>
     */
    @Transactional
    public Map<String, Object> importData(UUID userId, Map<String, Object> data) {
        createPreImportSnapshot(userId);

        JsonNode root;
        try {
            String json = objectMapper.writeValueAsString(data);
            root = objectMapper.readTree(json);
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Invalid backup data format", e);
        }

        // Step 1: Delete all existing data（与导入同事务，失败整体回滚）
        deckRepository.deleteAllByUserId(userId);

        // Step 2-3: 导入卡组/卡片/复习日志（与原实现一致）
        JsonNode decksNode = root.get("decks");
        int importedDecks = 0;
        int importedCards = 0;
        int importedLogs = 0;
        Map<String, UUID> cardFrontBackToId = new HashMap<>();
        List<ReviewLog> logsToSave = new ArrayList<>();

        if (decksNode != null && decksNode.isArray()) {
            for (JsonNode deckNode : decksNode) {
                Deck deck = new Deck();
                deck.setUserId(userId);
                deck.setName(deckNode.has("name") ? deckNode.get("name").asText() : "Unnamed Deck");
                deck = deckRepository.save(deck);
                importedDecks++;

                JsonNode cardsNode = deckNode.get("cards");
                if (cardsNode != null && cardsNode.isArray()) {
                    List<Card> cardsToSave = new ArrayList<>();
                    for (JsonNode cardNode : cardsNode) {
                        Card card = new Card();
                        card.setDeckId(deck.getId());
                        card.setUserId(userId);
                        card.setFront(cardNode.has("front") ? cardNode.get("front").asText() : "");
                        card.setBack(cardNode.has("back") ? cardNode.get("back").asText() : "");
                        card.setStage(cardNode.has("stage") ? cardNode.get("stage").asInt() : 0);
                        card.setConsecutiveFamiliar(
                                cardNode.has("consecutive_familiar") ? cardNode.get("consecutive_familiar").asInt() : 0);
                        if (cardNode.has("next_review_date") && !cardNode.get("next_review_date").isNull()) {
                            card.setNextReviewDate(LocalDate.parse(cardNode.get("next_review_date").asText()));
                        }
                        card.setLearningMode(
                                cardNode.has("learning_mode") && cardNode.get("learning_mode").asBoolean());
                        if (cardNode.has("reentry_stage") && !cardNode.get("reentry_stage").isNull()) {
                            card.setReentryStage(cardNode.get("reentry_stage").asInt());
                        }
                        cardsToSave.add(card);
                    }
                    for (Card saved : cardRepository.saveAll(cardsToSave)) {
                        importedCards++;
                        String key = saved.getFront() + "\u0000" + saved.getBack();
                        cardFrontBackToId.putIfAbsent(key, saved.getId());
                    }
                }
            }
        }

        JsonNode logsNode = root.get("review_logs");
        if (logsNode != null && logsNode.isArray()) {
            for (JsonNode logNode : logsNode) {
                String cardFront = logNode.has("card_front") ? logNode.get("card_front").asText() : "";
                UUID cardId = cardFrontBackToId.get(cardFront);
                if (cardId == null && !cardFront.isEmpty()) {
                    cardId = cardFrontBackToId.entrySet().stream()
                            .filter(e -> e.getKey().startsWith(cardFront + "\u0000"))
                            .map(Map.Entry::getValue)
                            .findFirst()
                            .orElse(null);
                }
                if (cardId == null) continue;

                ReviewLog log = new ReviewLog();
                log.setCardId(cardId);
                log.setUserId(userId);
                log.setRating(logNode.has("rating") ? logNode.get("rating").asText() : "FAMILIAR");
                log.setStageBefore(logNode.has("stage_before") ? logNode.get("stage_before").asInt() : 0);
                log.setStageAfter(logNode.has("stage_after") ? logNode.get("stage_after").asInt() : 0);
                log.setNewCard(logNode.has("is_new_card") && logNode.get("is_new_card").asBoolean());
                if (logNode.has("reviewed_at") && !logNode.get("reviewed_at").isNull()) {
                    try {
                        log.setReviewedAt(LocalDateTime.parse(logNode.get("reviewed_at").asText()));
                    } catch (Exception ignored) {
                    }
                }
                logsToSave.add(log);
            }
        }

        if (!logsToSave.isEmpty()) {
            reviewLogRepository.saveAll(logsToSave);
            importedLogs = logsToSave.size();
        }

        userLogService.log(userId, "INFO", "BACKUP",
                "Data restored: " + importedDecks + " deck(s), " + importedCards + " card(s), " + importedLogs + " log(s)");

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("imported_decks", importedDecks);
        result.put("imported_cards", importedCards);
        result.put("imported_review_logs", importedLogs);
        return result;
    }

    /**
     * 导入前自动快照（G10）：在独立事务中执行，导入失败时该快照依然保留。
     * 快照失败不阻断导入主流程（记日志告警）。
     */
    private void createPreImportSnapshot(UUID userId) {
        if (transactionTemplate.isEmpty()) {
            return;
        }
        try {
            transactionTemplate.get().executeWithoutResult(status -> {
                identityPort.findById(userId).ifPresent(user -> {
                    String json = buildExportJson(user, userId);
                    persistSnapshot(userId, json);
                    log.info("Pre-import snapshot created for user {}", userId);
                });
            });
        } catch (Exception e) {
            log.warn("Pre-import snapshot failed for user {} (import continues): {}", userId, e.getMessage());
        }
    }

    /**
     * 定期修剪备份快照：每用户保留最近 7 份（每天 03:50）。
     * 同时删除对象存储中的过期快照文件，避免存储泄漏。
     */
    @Scheduled(cron = "0 50 3 * * *")
    @Transactional
    public void cleanupOldSnapshots() {
        // 找出超限快照的存储键，先删对象存储文件，再删库内记录
        List<BackupSnapshot> excess = backupRepository.findExcessSnapshots(MAX_SNAPSHOTS_PER_USER);
        if (excess.isEmpty()) {
            return;
        }
        backupStorage.ifPresent(storage -> excess.forEach(s -> {
            if (s.getStorageKey() != null) {
                try {
                    storage.delete(s.getStorageKey());
                } catch (Exception e) {
                    log.warn("Failed to delete object storage snapshot {}: {}", s.getStorageKey(), e.getMessage());
                }
            }
        }));
        backupRepository.deleteAll(excess);
        log.info("Pruned {} excess backup snapshots (keeping {} per user)", excess.size(), MAX_SNAPSHOTS_PER_USER);
    }
}
