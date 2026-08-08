package top.kariscode.karisreview.common.etag;

import org.springframework.stereotype.Service;
import top.kariscode.karisreview.common.util.DateUtils;

import java.time.LocalDate;
import java.util.UUID;

/**
 * 用户级 ETag 生成（架构评审 B2，2026-08-08）。
 *
 * <p>此前用 JdbcTemplate 手写 SQL 直查 sync_events/users 表（与
 * SyncEventRepository 的 latestSeq 是同一句 SQL 的两份副本、且越过 auth 模块）。
 * 现收敛为两个 common 接口（SyncEventSeqQuery / UserRefreshTimeQuery），
 * 由 sync/auth 模块实现，common 恢复零业务依赖底座。</p>
 */
@Service
public class UserEtagService {

    private static final String VERSION_PREFIX = "karis-review-api-v1";

    private final SyncEventSeqQuery syncEventSeqQuery;
    private final UserRefreshTimeQuery userRefreshTimeQuery;

    public UserEtagService(SyncEventSeqQuery syncEventSeqQuery,
                           UserRefreshTimeQuery userRefreshTimeQuery) {
        this.syncEventSeqQuery = syncEventSeqQuery;
        this.userRefreshTimeQuery = userRefreshTimeQuery;
    }

    public String decksEtag(UUID userId) {
        return etag("decks", userId, null);
    }

    public String overviewEtag(UUID userId) {
        return etag("overview", userId, null);
    }

    public String deckStatsEtag(UUID userId, UUID deckId) {
        return etag("deck-stats", userId, deckId);
    }

    public String trendEtag(UUID userId) {
        return etag("trend", userId, null);
    }

    private String etag(String kind, UUID userId, UUID deckId) {
        long eventSeq = syncEventSeqQuery.latestSeq(userId);
        LocalDate today = todayFor(userId);
        String suffix = deckId == null ? "" : "-" + deckId;
        return "W/\"" + VERSION_PREFIX + "-" + kind + "-" + eventSeq
                + "-" + today + suffix + "\"";
    }

    private LocalDate todayFor(UUID userId) {
        return DateUtils.calculateToday(userRefreshTimeQuery.resolve(userId));
    }
}
