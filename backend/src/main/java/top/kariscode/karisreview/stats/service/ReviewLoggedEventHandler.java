package top.kariscode.karisreview.stats.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import top.kariscode.karisreview.common.outbox.DomainEvent;
import top.kariscode.karisreview.common.outbox.DomainEventHandler;
import top.kariscode.karisreview.common.outbox.OutboxEventTypes;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * 复习日志事件处理器：消费 REVIEW_LOGGED 事件，增量更新每日统计预聚合。
 * （阶段二 Analytics 事件驱动化的单体内部实现：统计模块通过事件流与复习模块解耦）
 */
@Component
public class ReviewLoggedEventHandler implements DomainEventHandler {

    private static final Logger log = LoggerFactory.getLogger(ReviewLoggedEventHandler.class);

    private final DailyReviewStatsService statsService;
    private final ObjectMapper objectMapper;

    public ReviewLoggedEventHandler(DailyReviewStatsService statsService, ObjectMapper objectMapper) {
        this.statsService = statsService;
        this.objectMapper = objectMapper;
    }

    @Override
    public boolean supports(String eventType) {
        return OutboxEventTypes.REVIEW_LOGGED.equals(eventType);
    }

    @Override
    public void handle(DomainEvent event) {
        try {
            JsonNode payload = objectMapper.readTree(event.payload());
            UUID userId = UUID.fromString(payload.get("userId").asText());
            UUID deckId = payload.hasNonNull("deckId")
                    ? UUID.fromString(payload.get("deckId").asText())
                    : null;
            String rating = payload.get("rating").asText();
            boolean newCard = payload.get("isNewCard").asBoolean();
            LocalDateTime reviewedAt = LocalDateTime.parse(payload.get("reviewedAt").asText());
            statsService.incrementFromEvent(userId, deckId, reviewedAt, newCard, rating);
        } catch (Exception e) {
            log.warn("Failed to process REVIEW_LOGGED event {}: {}", event.eventType(), e.getMessage());
            throw new RuntimeException(e);
        }
    }
}
