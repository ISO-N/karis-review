package top.kariscode.karisreview.common.outbox;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Outbox 投递器：定时轮询 PENDING 事件，分发给匹配的 {@link DomainEventHandler}。
 *
 * <p>可靠性设计：
 * <ul>
 *   <li>批量领取（SKIP LOCKED）支持多实例并发投递不重复处理；</li>
 *   <li>失败按指数退避重试（1s → 2s → 4s …），超过 {@code maxAttempts} 进入 DEAD 死信；</li>
 *   <li>死信保留 30 天供人工排查，已处理记录保留 7 天后清理。</li>
 * </ul>
 */
@Service
public class OutboxRelay {

    private static final Logger log = LoggerFactory.getLogger(OutboxRelay.class);

    private final OutboxRepository outboxRepository;
    private final ObjectMapper objectMapper;
    private final List<DomainEventHandler> handlers;
    private final HttpExternalEventPublisher externalPublisher;
    private final int batchSize;
    private final Duration staleLockThreshold;

    public OutboxRelay(OutboxRepository outboxRepository,
                       ObjectMapper objectMapper,
                       List<DomainEventHandler> handlers,
                       HttpExternalEventPublisher externalPublisher,
                       @Value("${app.outbox.batch-size:100}") int batchSize,
                       @Value("${app.outbox.stale-lock-threshold:5m}") Duration staleLockThreshold) {
        this.outboxRepository = outboxRepository;
        this.objectMapper = objectMapper;
        this.handlers = handlers;
        this.externalPublisher = externalPublisher;
        this.batchSize = batchSize;
        this.staleLockThreshold = staleLockThreshold;
    }

    @Scheduled(fixedDelayString = "${app.outbox.poll-interval:2000}")
    @Transactional
    public void relay() {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime stale = now.minus(staleLockThreshold);

        int claimed = outboxRepository.claimBatch(now, stale, batchSize);
        if (claimed == 0) {
            return;
        }

        List<OutboxEvent> events = outboxRepository.findClaimed(now, batchSize);
        for (OutboxEvent event : events) {
            process(event, now);
        }
    }

    private void process(OutboxEvent event, LocalDateTime now) {
        DomainEvent domainEvent = toDomainEvent(event);
        try {
            boolean handled = dispatch(domainEvent);
            if (!handled) {
                // 没有处理器：视为已处理（防止孤儿事件无限重试），记录告警
                log.warn("No handler for outbox event type={} id={}", event.getEventType(), event.getId());
            }
            // 转发到外部事件端点（阶段二事件流：Analytics/Identity 拆分后订阅）
            externalPublisher.publish(domainEvent);
            event.setStatus(OutboxEvent.STATUS_PROCESSED);
            event.setProcessedAt(LocalDateTime.now());
            event.setLockedAt(null);
            outboxRepository.save(event);
        } catch (Exception e) {
            event.setAttempts(event.getAttempts() + 1);
            event.setLastError(truncate(e.getMessage()));
            if (event.getAttempts() >= event.getMaxAttempts()) {
                event.setStatus(OutboxEvent.STATUS_DEAD);
                event.setProcessedAt(LocalDateTime.now());
                log.error("Outbox event {} became DEAD after {} attempts: {}",
                        event.getId(), event.getAttempts(), e.getMessage(), e);
            } else {
                long backoffMillis = 1000L << Math.min(event.getAttempts() - 1, 10);
                event.setNextAttemptAt(now.plusNanos(java.time.Duration.ofMillis(backoffMillis).toNanos()));
                log.warn("Outbox event {} failed (attempt {}/{}), retry in {}ms: {}",
                        event.getId(), event.getAttempts(), event.getMaxAttempts(),
                        backoffMillis, e.getMessage());
            }
            event.setLockedAt(null);
            outboxRepository.save(event);
        }
    }

    private boolean dispatch(DomainEvent event) {
        boolean any = false;
        for (DomainEventHandler handler : handlers) {
            if (handler.supports(event.eventType())) {
                handler.handle(event);
                any = true;
            }
        }
        return any;
    }

    private DomainEvent toDomainEvent(OutboxEvent entity) {
        String aggregateId = entity.getAggregateId() != null ? entity.getAggregateId().toString() : null;
        return new DomainEvent(entity.getAggregateType(), aggregateId, entity.getEventType(), entity.getPayload());
    }

    private String truncate(String msg) {
        if (msg == null) {
            return null;
        }
        return msg.length() > 500 ? msg.substring(0, 500) : msg;
    }

    /** 供处理器解析 JSON 载荷。 */
    public JsonNode parsePayload(String payload) {
        try {
            return objectMapper.readTree(payload);
        } catch (Exception e) {
            throw new IllegalArgumentException("Invalid event payload", e);
        }
    }

    /** 便捷方法：把记录转为 Map（供处理器使用）。 */
    public Map<String, Object> payloadMap(String payload) {
        try {
            return objectMapper.readValue(payload, Map.class);
        } catch (Exception e) {
            return new HashMap<>();
        }
    }
}
