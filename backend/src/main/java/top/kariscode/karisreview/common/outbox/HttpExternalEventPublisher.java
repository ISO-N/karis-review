package top.kariscode.karisreview.common.outbox;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.Map;

/**
 * 外部事件发布器：把领域事件以 HTTP POST 推送到配置的事件端点。
 *
 * <p>阶段二 M7 的落地形态：Analytics（或未来拆出的 Identity 服务）订阅该端点消费事件。
 * 在单体内部，{@link OutboxRelay} 同时分发到进程内处理器（{@link DomainEventHandler}）与
 * 本发布器；拆服务后，进程内处理器迁移到订阅方即可无缝切换。
 *
 * <p>配置：
 * <pre>
 * app.events.external-endpoint=http://analytics:8080/events   # 留空则仅记录日志
 * </pre>
 */
@Component
public class HttpExternalEventPublisher {

    private static final Logger log = LoggerFactory.getLogger(HttpExternalEventPublisher.class);

    private final RestClient restClient;
    private final String endpoint;
    private final boolean enabled;

    public HttpExternalEventPublisher(@Value("${app.events.external-endpoint:}") String endpoint) {
        this.endpoint = endpoint;
        this.enabled = endpoint != null && !endpoint.isBlank();
        this.restClient = enabled ? RestClient.create() : null;
    }

    /**
     * 推送到外部事件端点；未配置端点时仅记日志（单体内部已由进程内 handler 处理）。
     * 失败抛出异常 → 由 OutboxRelay 重试，保证事件不丢失。
     */
    public void publish(DomainEvent event) {
        if (!enabled) {
            log.debug("External event publishing disabled (no endpoint); event={}", event.eventType());
            return;
        }
        Map<String, Object> body = Map.of(
                "aggregateType", event.aggregateType(),
                "aggregateId", event.aggregateId() == null ? "" : event.aggregateId(),
                "eventType", event.eventType(),
                "payload", event.payload());
        restClient.post()
                .uri(endpoint)
                .body(body)
                .retrieve()
                .toBodilessEntity();
        log.debug("Published event {} to {}", event.eventType(), endpoint);
    }
}
