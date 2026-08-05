package top.kariscode.karisreview.common.outbox;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Duration;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OutboxRelayTest {

    @Mock
    private OutboxRepository outboxRepository;

    @Mock
    private HttpExternalEventPublisher externalPublisher;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private OutboxRelay relay;

    @BeforeEach
    void setUp() {
        relay = new OutboxRelay(outboxRepository, objectMapper,
                List.of(new CapturingHandler()), externalPublisher, 100, Duration.ofMinutes(5));
    }

    static class CapturingHandler implements DomainEventHandler {
        int handled = 0;
        boolean throwError = false;
        @Override
        public boolean supports(String eventType) {
            return "TEST_EVENT".equals(eventType);
        }
        @Override
        public void handle(DomainEvent event) {
            handled++;
            if (throwError) {
                throw new RuntimeException("handler failed");
            }
        }
    }

    @Test
    void relayMarksEventProcessedOnSuccess() {
        OutboxEvent event = pendingEvent();
        event.setStatus(OutboxEvent.STATUS_PENDING);
        when(outboxRepository.claimBatch(any(), any(), anyInt())).thenReturn(1);
        when(outboxRepository.findClaimed(any(), anyInt())).thenReturn(List.of(event));

        relay.relay();

        assertEquals(OutboxEvent.STATUS_PROCESSED, event.getStatus());
        assertTrue(event.getProcessedAt() != null);
        verify(outboxRepository).save(event);
    }

    @Test
    void relayRetriesWithBackoffOnFailure() {
        OutboxEvent event = pendingEvent();
        event.setStatus(OutboxEvent.STATUS_PENDING);
        event.setMaxAttempts(3);
        when(outboxRepository.claimBatch(any(), any(), anyInt())).thenReturn(1);
        when(outboxRepository.findClaimed(any(), anyInt())).thenReturn(List.of(event));

        CapturingHandler failing = new CapturingHandler();
        failing.throwError = true;
        relay = new OutboxRelay(outboxRepository, objectMapper,
                List.of(failing), externalPublisher, 100, Duration.ofMinutes(5));
        relay.relay();

        assertEquals(1, event.getAttempts());
        assertEquals(OutboxEvent.STATUS_PENDING, event.getStatus());
        assertTrue(event.getNextAttemptAt().isAfter(event.getCreatedAt()));
        assertTrue(event.getLastError().contains("handler failed"));
    }

    @Test
    void relayMarksDeadAfterMaxAttempts() {
        OutboxEvent event = pendingEvent();
        event.setStatus(OutboxEvent.STATUS_PENDING);
        event.setMaxAttempts(2);
        event.setAttempts(2); // 已重试过，这次是第 3 次
        when(outboxRepository.claimBatch(any(), any(), anyInt())).thenReturn(1);
        when(outboxRepository.findClaimed(any(), anyInt())).thenReturn(List.of(event));

        CapturingHandler failing = new CapturingHandler();
        failing.throwError = true;
        relay = new OutboxRelay(outboxRepository, objectMapper,
                List.of(failing), externalPublisher, 100, Duration.ofMinutes(5));
        relay.relay();

        assertEquals(OutboxEvent.STATUS_DEAD, event.getStatus());
        assertTrue(event.getProcessedAt() != null);
    }

    private OutboxEvent pendingEvent() {
        OutboxEvent e = new OutboxEvent();
        e.setAggregateType("test");
        e.setEventType("TEST_EVENT");
        e.setPayload("{\"k\":\"v\"}");
        e.setMaxAttempts(10);
        // 模拟 @PrePersist 写入的时间字段（单元测试不走 JPA 生命周期）
        java.time.LocalDateTime now = java.time.LocalDateTime.now();
        try {
            java.lang.reflect.Field f = OutboxEvent.class.getDeclaredField("createdAt");
            f.setAccessible(true);
            f.set(e, now);
            f = OutboxEvent.class.getDeclaredField("nextAttemptAt");
            f.setAccessible(true);
            f.set(e, now);
        } catch (Exception ignored) {
        }
        return e;
    }
}
