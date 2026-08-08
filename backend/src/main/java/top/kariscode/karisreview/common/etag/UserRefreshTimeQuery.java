package top.kariscode.karisreview.common.etag;

import java.time.LocalTime;
import java.util.UUID;

/**
 * 用户每日刷新点查询（架构评审 B2，2026-08-08）。
 *
 * <p>common 包是零业务依赖底座：ETag 的「今天」边界依赖 auth 模块的
 * refresh_time，经本接口读取，实现由 auth 模块提供（UserRefreshTimeService），
 * 依赖方向 common ← auth，编译期无环。兜底 04:00 语义由实现保证
 * （UserRefreshTime.DEFAULT_REFRESH_TIME），勿在 common 内复制。</p>
 */
public interface UserRefreshTimeQuery {

    /**
     * 用户每日刷新点（无配置时兜底 04:00）。
     */
    LocalTime resolve(UUID userId);
}
