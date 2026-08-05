package top.kariscode.karisreview.common.outbox;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 事件发布器：在业务事务内将领域事件写入 Outbox 表。
 * 与业务写操作同事务提交，保证不丢失事件（"业务提交即事件入盒"）。
 */
@Service
public class OutboxPublisher {

    private final OutboxRepository outboxRepository;

    public OutboxPublisher(OutboxRepository outboxRepository) {
        this.outboxRepository = outboxRepository;
    }

    /**
     * 发布领域事件。调用方应处于业务事务中（REQUIRED 传播），
     * 事件将与业务数据一起提交或一起回滚。
     */
    @Transactional
    public void publish(DomainEvent event) {
        OutboxEvent entity = new OutboxEvent();
        entity.setAggregateType(event.aggregateType());
        entity.setAggregateId(event.aggregateId() != null ? java.util.UUID.fromString(event.aggregateId()) : null);
        entity.setEventType(event.eventType());
        entity.setPayload(event.payload());
        outboxRepository.save(entity);
    }
}
