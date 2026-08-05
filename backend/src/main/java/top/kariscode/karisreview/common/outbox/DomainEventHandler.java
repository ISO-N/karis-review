package top.kariscode.karisreview.common.outbox;

/**
 * 领域事件处理器：消费 {@link DomainEvent} 完成副作用（发邮件、更新预聚合、转发外部系统等）。
 * 处理器抛异常时事件将进入重试队列（指数退避），因此处理器必须可重入（幂等）。
 */
public interface DomainEventHandler {

    boolean supports(String eventType);

    void handle(DomainEvent event);
}
