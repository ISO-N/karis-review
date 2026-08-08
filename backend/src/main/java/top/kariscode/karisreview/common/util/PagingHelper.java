package top.kariscode.karisreview.common.util;

/**
 * 分页/参数保护统一工具（架构评审 B4，2026-08-08）。
 *
 * <p>分页 clamp 此前三套并存：UserLogService safePage/safeSize、ReviewService
 * safeLimit、CardController 无上限（可传 10 万拉全表）、StatsController days
 * 无上限。统一收口：page ≥ 0、1 ≤ size ≤ [maxSize]、days 限 1..[maxDays]。</p>
 */
public final class PagingHelper {

    /** 通用单页上限（列表/日志）。 */
    public static final int DEFAULT_MAX_PAGE_SIZE = 100;

    /** 趋势统计最大天数。 */
    public static final int MAX_TREND_DAYS = 365;

    private PagingHelper() {
    }

    /** 页码下限保护：page ≥ 0。 */
    public static int safePage(int page) {
        return Math.max(0, page);
    }

    /** 页大小保护：1 ≤ size ≤ maxSize。 */
    public static int safeSize(int size, int maxSize) {
        return Math.max(1, Math.min(maxSize, size));
    }

    /** 页大小保护（默认上限 [DEFAULT_MAX_PAGE_SIZE]）。 */
    public static int safeSize(int size) {
        return safeSize(size, DEFAULT_MAX_PAGE_SIZE);
    }

    /** 趋势天数保护：1 ≤ days ≤ MAX_TREND_DAYS。 */
    public static int safeTrendDays(int days) {
        return Math.max(1, Math.min(MAX_TREND_DAYS, days));
    }
}
