package top.kariscode.karisreview.backup.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import top.kariscode.karisreview.backup.entity.BackupSnapshot;
import top.kariscode.karisreview.backup.repository.BackupRepository;
import top.kariscode.karisreview.card.entity.Card;
import top.kariscode.karisreview.card.entity.SchedulingState;
import top.kariscode.karisreview.card.repository.CardRepository;
import top.kariscode.karisreview.common.util.DateUtils;
import top.kariscode.karisreview.deck.entity.Deck;
import top.kariscode.karisreview.deck.repository.DeckRepository;
import top.kariscode.karisreview.log.service.UserLogService;
import top.kariscode.karisreview.review.entity.ReviewLog;
import top.kariscode.karisreview.review.repository.ReviewLogRepository;
import top.kariscode.karisreview.auth.entity.User;
import top.kariscode.karisreview.auth.repository.UserRepository;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Service
public class BackupService {

    private static final Logger log = LoggerFactory.getLogger(BackupService.class);

    /** 每个用户最多保留的全量快照份数（与 V13 迁移一致）。 */
    private static final int MAX_SNAPSHOTS_PER_USER = 7;

    private final UserRepository userRepository;
    private final DeckRepository deckRepository;
    private final CardRepository cardRepository;
    private final ReviewLogRepository reviewLogRepository;
    private final BackupRepository backupRepository;
    private final ObjectMapper objectMapper;
    private final UserLogService userLogService;

    public BackupService(UserRepository userRepository,
                         DeckRepository deckRepository,
                         CardRepository cardRepository,
                         ReviewLogRepository reviewLogRepository,
                         BackupRepository backupRepository,
                         ObjectMapper objectMapper,
                         UserLogService userLogService) {
        this.userRepository = userRepository;
        this.deckRepository = deckRepository;
        this.cardRepository = cardRepository;
        this.reviewLogRepository = reviewLogRepository;
        this.backupRepository = backupRepository;
        this.objectMapper = objectMapper;
        this.userLogService = userLogService;
    }

    @Transactional
    public Map<String, Object> exportData(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("用户不存在"));

        List<Deck> decks = deckRepository.findByUserIdOrderByCreatedAtAsc(userId);

        // Build export JSON
        ObjectNode root = objectMapper.createObjectNode();
        // exported_at 走 DateUtils.now()（业务时区 AppTimeZone），与全局时区口径一致
        // （此前 LocalDateTime.now() 用 JVM 本地时区，架构评审 B4）。
        root.put("exported_at", DateUtils.now().toString());

        // User info
        ObjectNode userNode = root.putObject("user");
        userNode.put("email", user.getEmail());
        userNode.put("refresh_time", user.getRefreshTime().format(DateTimeFormatter.ofPattern("HH:mm:ss")));

        // Decks with cards
        ArrayNode decksArray = root.putArray("decks");
        for (Deck deck : decks) {
            ObjectNode deckNode = decksArray.addObject();
            deckNode.put("name", deck.getName());
            ArrayNode cardsArray = deckNode.putArray("cards");
            List<Card> cards = cardRepository.findByDeckIdOrderByCreatedAtAsc(deck.getId());
            for (Card card : cards) {
                ObjectNode cardNode = cardsArray.addObject();
                // 携带原 card_id，导入时直连恢复（架构评审 B4）：
                // 此前只写 front/back 文本，恢复靠 front 匹配，同 front 多卡会错挂第一张。
                cardNode.put("id", card.getId().toString());
                cardNode.put("front", card.getFront());
                cardNode.put("back", card.getBack());
                // 排期状态经 SchedulingState 全字段投影（架构评审候选 2）：
                // 曾漏 learning_step/learning_origin/review_version 导致恢复后
                // 队列归属退化与重学插位丢失。
                card.getSchedulingState().writeTo(cardNode);
                cardNode.put("review_version", card.getReviewVersion());
            }
        }

        // Review logs
        ArrayNode logsArray = root.putArray("review_logs");
        List<ReviewLog> logs = reviewLogRepository.findByUserIdOrderByReviewedAtDesc(userId);
        Map<UUID, String> cardFrontMap = new HashMap<>();
        for (ReviewLog log : logs) {
            cardFrontMap.putIfAbsent(log.getCardId(), "");
        }
        // 批量取卡片正面文本（替代逐条 findById，避免 N+1）
        for (Card c : cardRepository.findAllById(cardFrontMap.keySet())) {
            cardFrontMap.put(c.getId(), c.getFront());
        }

        for (ReviewLog log : logs) {
            ObjectNode logNode = logsArray.addObject();
            // 携带原 card_id（架构评审 B4）：导入时直连恢复；
            // card_front 保留，兼容旧版本导入工具。
            logNode.put("card_id", log.getCardId().toString());
            logNode.put("card_front", cardFrontMap.getOrDefault(log.getCardId(), ""));
            logNode.put("rating", log.getRating());
            logNode.put("stage_before", log.getStageBefore());
            logNode.put("stage_after", log.getStageAfter());
            logNode.put("is_new_card", log.isNewCard());
            logNode.put("learning_origin", log.getLearningOrigin());
            logNode.put("reviewed_at", log.getReviewedAt().toString());
        }

        // Save backup snapshot
        BackupSnapshot snapshot = new BackupSnapshot();
        snapshot.setUserId(userId);
        try {
            snapshot.setData(objectMapper.writeValueAsString(root));
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Failed to serialize backup data", e);
        }
        snapshot = backupRepository.save(snapshot);

        userLogService.log(userId, "INFO", "BACKUP",
                "Backup created with " + decks.size() + " deck(s)");

        // Parse the data back for the response
        try {
            JsonNode dataNode = objectMapper.readTree(snapshot.getData());
            Map<String, Object> response = new LinkedHashMap<>();
            response.put("backup_id", snapshot.getId().toString());
            response.put("exported_at", snapshot.getCreatedAt().toString());
            response.put("data", objectMapper.treeToValue(dataNode, Map.class));
            return response;
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Failed to parse backup data", e);
        }
    }

    @Transactional
    public Map<String, Object> importData(UUID userId, Map<String, Object> data) {
        JsonNode root;
        try {
            String json = objectMapper.writeValueAsString(data);
            root = objectMapper.readTree(json);
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Invalid backup data format", e);
        }

        // Step 1: Delete all existing data for this user（批量删除，数据库级联 + 触发器照常记录）
        deckRepository.deleteAllByUserId(userId);

        // Step 2: Import decks, cards, and track each new card so review logs can be
        // re-attached after the imported cards receive fresh IDs.
        // 直连恢复（架构评审 B4）：新备份携带原 card_id，按备份 id → 新 id 映射；
        // 旧备份（无 id）回退 front+back 文本映射。
        JsonNode decksNode = root.get("decks");
        int importedDecks = 0;
        int importedCards = 0;
        int importedLogs = 0;
        Map<String, UUID> backupCardIdToNewId = new HashMap<>();
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
                    List<String> backupCardIds = new ArrayList<>();
                    for (JsonNode cardNode : cardsNode) {
                        Card card = new Card();
                        card.setDeckId(deck.getId());
                        card.setUserId(userId);
                        card.setFront(cardNode.has("front") ? cardNode.get("front").asText() : "");
                        card.setBack(cardNode.has("back") ? cardNode.get("back").asText() : "");
                        // 排期状态整体恢复（架构评审候选 2）；旧备份缺键自动回退默认。
                        card.applySchedulingState(SchedulingState.fromJson(cardNode));
                        if (cardNode.has("review_version")) {
                            card.setReviewVersion(cardNode.get("review_version").asLong());
                        }
                        backupCardIds.add(
                                (cardNode.has("id") && !cardNode.get("id").isNull())
                                        ? cardNode.get("id").asText()
                                        : null);
                        cardsToSave.add(card);
                    }
                    // 批量插入（配合 hibernate.jdbc.batch_size 真正合并为批次 INSERT），
                    // saveAll 顺序与入参一致，backupCardIds 与 saved 按索引对应。
                    List<Card> savedCards = cardRepository.saveAll(cardsToSave);
                    for (int i = 0; i < savedCards.size(); i++) {
                        Card saved = savedCards.get(i);
                        importedCards++;
                        String backupId = backupCardIds.get(i);
                        if (backupId != null) {
                            backupCardIdToNewId.put(backupId, saved.getId());
                        }
                        String key = saved.getFront() + "\u0000" + saved.getBack();
                        cardFrontBackToId.putIfAbsent(key, saved.getId());
                    }
                }
            }
        }

        // Step 3: Import review logs。优先按备份 card_id 直连恢复；
        // 旧备份（无 card_id）回退 front 文本匹配——同 front 多卡取首个匹配（原语义兜底）。
        JsonNode logsNode = root.get("review_logs");

        if (logsNode != null && logsNode.isArray()) {
            for (JsonNode logNode : logsNode) {
                UUID cardId = null;
                if (logNode.has("card_id") && !logNode.get("card_id").isNull()) {
                    cardId = backupCardIdToNewId.get(logNode.get("card_id").asText());
                }
                if (cardId == null) {
                    String cardFront = logNode.has("card_front") ? logNode.get("card_front").asText() : "";
                    cardId = cardFrontBackToId.get(cardFront);
                    if (cardId == null && !cardFront.isEmpty()) {
                        // Fallback: find any imported card with the same front content.
                        cardId = cardFrontBackToId.entrySet().stream()
                                .filter(e -> e.getKey().startsWith(cardFront + "\u0000"))
                                .map(Map.Entry::getValue)
                                .findFirst()
                                .orElse(null);
                    }
                }
                if (cardId == null) continue;

                ReviewLog log = new ReviewLog();
                log.setCardId(cardId);
                log.setUserId(userId);
                log.setRating(logNode.has("rating") ? logNode.get("rating").asText() : "FAMILIAR");
                log.setStageBefore(logNode.has("stage_before") ? logNode.get("stage_before").asInt() : 0);
                log.setStageAfter(logNode.has("stage_after") ? logNode.get("stage_after").asInt() : 0);
                log.setNewCard(logNode.has("is_new_card") && logNode.get("is_new_card").asBoolean());
                if (logNode.has("learning_origin") && !logNode.get("learning_origin").isNull()) {
                    log.setLearningOrigin(logNode.get("learning_origin").asText());
                }
                if (logNode.has("reviewed_at") && !logNode.get("reviewed_at").isNull()) {
                    try {
                        log.setReviewedAt(LocalDateTime.parse(logNode.get("reviewed_at").asText()));
                    } catch (Exception ignored) {
                        // Keep default now() when the timestamp is not parseable.
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
     * 定期修剪备份快照：每个用户仅保留最近 7 份（每天 03:50，与其它清理任务错开）。
     */
    @Scheduled(cron = "0 50 3 * * *")
    @Transactional
    public void cleanupOldSnapshots() {
        int deleted = backupRepository.deleteExcessSnapshots(MAX_SNAPSHOTS_PER_USER);
        if (deleted > 0) {
            log.info("Pruned {} excess backup snapshots (keeping {} per user)",
                    deleted, MAX_SNAPSHOTS_PER_USER);
        }
    }
}