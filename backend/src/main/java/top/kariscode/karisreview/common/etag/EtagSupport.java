package top.kariscode.karisreview.common.etag;

/**
 * ETag 校验工具（架构评审 B4，2026-08-08）。
 *
 * <p>If-None-Match 匹配语义（"*" 通配 + 精确匹配）此前在 DeckController /
 * StatsController 逐字复制，现收敛为单一实现；将来若支持弱比较/多 ETag 列表
 * 只改此处。匹配命中时调用方应返回 304 + eTag，否则正常响应。</p>
 */
public final class EtagSupport {

    private EtagSupport() {
    }

    /**
     * If-None-Match 是否命中当前 ETag：值为 "*"（任意资源）或与 ETag 精确相等。
     */
    public static boolean matches(String ifNoneMatch, String etag) {
        return ifNoneMatch != null && ("*".equals(ifNoneMatch) || ifNoneMatch.equals(etag));
    }
}
