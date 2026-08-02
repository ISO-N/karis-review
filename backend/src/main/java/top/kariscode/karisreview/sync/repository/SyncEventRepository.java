package top.kariscode.karisreview.sync.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public class SyncEventRepository {

    private final JdbcTemplate jdbcTemplate;

    public SyncEventRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public long latestSeq(UUID userId) {
        Long seq = jdbcTemplate.queryForObject(
                "SELECT COALESCE(MAX(event_seq), 0) FROM sync_events WHERE user_id = ?",
                Long.class, userId);
        return seq == null ? 0 : seq;
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
