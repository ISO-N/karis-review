package top.kariscode.karisreview.auth.service;

import org.springframework.stereotype.Service;
import top.kariscode.karisreview.auth.repository.UserRepository;
import top.kariscode.karisreview.auth.util.UserRefreshTime;
import top.kariscode.karisreview.common.etag.UserRefreshTimeQuery;

import java.time.Instant;
import java.time.LocalTime;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

/**
 * UserRefreshTimeQuery 实现（架构评审 B2/B5，2026-08-08）。
 *
 * <p>common 的 ETag 与业务模块（review/card/stats）都需要用户刷新点计算「今天」，
 * 经 common 接口 UserRefreshTimeQuery 读取，本类在 auth 模块内实现——依赖方向
 * common ← auth，编译期无环。兜底 04:00 走 UserRefreshTime 单一实现。</p>
 *
 * <p>请求内缓存（B5）：StatsService 单请求最多 resolve 4 次、ReviewService 每次
 * 评分/队列构建都要读，加 30 秒 TTL 的内存缓存避免重复查 users 表；TTL 短于
 * 任何「改设置→重排程」的可见性窗口，不引入陈旧数据。</p>
 */
@Service
public class UserRefreshTimeService implements UserRefreshTimeQuery {

    private static final long CACHE_TTL_MILLIS = 30_000L;

    private final UserRepository userRepository;
    private final ConcurrentMap<UUID, CacheEntry> cache = new ConcurrentHashMap<>();

    public UserRefreshTimeService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    public LocalTime resolve(UUID userId) {
        CacheEntry entry = cache.get(userId);
        long now = Instant.now().toEpochMilli();
        if (entry != null && now - entry.recordedAt < CACHE_TTL_MILLIS) {
            return entry.refreshTime;
        }
        LocalTime resolved = UserRefreshTime.resolve(userRepository, userId);
        cache.put(userId, new CacheEntry(resolved, now));
        return resolved;
    }

    private record CacheEntry(LocalTime refreshTime, long recordedAt) {}
}
