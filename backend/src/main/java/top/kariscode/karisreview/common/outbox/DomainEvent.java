package top.kariscode.karisreview.common.outbox;

/**
 * 领域事件：在业务事务内发布，经 Outbox 持久化后异步投递。
 *
 * @param aggregateType 聚合类型（如 review_log / card / user / mail）
 * @param aggregateId   聚合 ID（可为空）
 * @param eventType     事件类型（如 REVIEW_LOGGED / MAIL_RESET_CODE / USER_REGISTERED）
 * @param payload       事件载荷（JSON 字符串）
 */
public record DomainEvent(String aggregateType, String aggregateId, String eventType, String payload) {
}
