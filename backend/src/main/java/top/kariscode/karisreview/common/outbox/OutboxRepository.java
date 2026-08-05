package top.kariscode.karisreview.common.outbox;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface OutboxRepository extends JpaRepository<OutboxEvent, UUID> {

    /**
     * 领取一批待投递事件：跳过被其他实例锁定的行（SKIP LOCKED 语义），
     * 并标记为投递中，防止多实例并发重复处理。
     */
    @Modifying
    @Query(value = "UPDATE outbox_events SET locked_at = :now " +
                   "WHERE id IN (SELECT id FROM outbox_events " +
                   "              WHERE status = 'PENDING' AND next_attempt_at <= :now " +
                   "              AND (locked_at IS NULL OR locked_at < :staleThreshold) " +
                   "              ORDER BY next_attempt_at ASC LIMIT :limit FOR UPDATE SKIP LOCKED)",
           nativeQuery = true)
    int claimBatch(@Param("now") LocalDateTime now,
                   @Param("staleThreshold") LocalDateTime staleThreshold,
                   @Param("limit") int limit);

    @Query(value = "SELECT * FROM outbox_events " +
                   "WHERE status = 'PENDING' AND locked_at = :lockedAt " +
                   "ORDER BY next_attempt_at ASC LIMIT :limit",
           nativeQuery = true)
    List<OutboxEvent> findClaimed(@Param("lockedAt") LocalDateTime lockedAt,
                                  @Param("limit") int limit);

    @Modifying
    @Query("DELETE FROM OutboxEvent e WHERE e.status = 'PROCESSED' AND e.processedAt < :before")
    int deleteProcessedBefore(@Param("before") LocalDateTime before);

    @Modifying
    @Query("DELETE FROM OutboxEvent e WHERE e.status = 'DEAD' AND e.updatedAt < :before")
    int deleteDeadBefore(@Param("before") LocalDateTime before);
}
