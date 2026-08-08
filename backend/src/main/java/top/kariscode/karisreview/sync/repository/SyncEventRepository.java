package top.kariscode.karisreview.sync.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import top.kariscode.karisreview.common.etag.SyncEventSeqQuery;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public class SyncEventRepository implements SyncEventSeqQuery {

    private final JdbcTemplate jdbcTemplate;

    public SyncEventRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    /**
     * SyncEventSeqQuery 实现（架构评审 B2）：common 的 ETag 经本方法取最新
     * 事件序号，SQL 唯一副本在此，禁止在 common 内重复手写。
     */
    @Override
    public long latestSeq(UUID userId) {
        Long seq = jdbcTemplate.queryForObject(
                "SELECT COALESCE(MAX(event_seq), 0) FROM sync_events WHERE user_id = ?",
                Long.class, userId);
        return seq == null ? 0 : seq;
    }

    public long minSeq(UUID userId) {
        Long seq = jdbcTemplate.queryForObject(
                "SELECT MIN(event_seq) FROM sync_events WHERE user_id = ?",
                Long.class, userId);
        return seq == null ? 0 : seq;
    }

    /**
     * 按保留策略删除 cutoff 之前的事件。调用方需保证事务边界；
     * 清理后旧客户端游标失效时，由 SyncService.deltaBootstrap 的
     * minSeq/latestSeq 检查自动降级为全量同步。
     */
    public int deleteOlderThan(LocalDateTime cutoff) {
        return jdbcTemplate.update(
                "DELETE FROM sync_events WHERE occurred_at < ?", cutoff);
    }

    public List<SyncEventRow> findAfter(UUID userId, long cursor, int limit) {
        return jdbcTemplate.query(
                "SELECT entity_type, entity_id, event_type, event_seq " +
                "FROM sync_events WHERE user_id = ? AND event_seq > ? " +
                "ORDER BY event_seq ASC LIMIT ?",
                (rs, rowNum) -> new SyncEventRow(
                        rs.getString("entity_type"),
                        UUID.fromString(rs.getString("entity_id")),
                        rs.getString("event_type"),
                        rs.getLong("event_seq")),
                userId, cursor, limit);
    }

    public record SyncEventRow(String entityType, UUID entityId, String eventType, long eventSeq) {}
}
