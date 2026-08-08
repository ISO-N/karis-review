package top.kariscode.karisreview.common.etag;

import java.util.UUID;

/**
 * 用户最新同步事件序号查询（架构评审 B2，2026-08-08）。
 *
 * <p>common 包是零业务依赖底座：ETag 失效语义依赖 sync 模块的 event_seq，
 * 经本接口读取，实现由 sync 模块提供（SyncEventRepository），依赖方向
 * common ← sync，编译期无环。禁止在 common 内直接手写 SQL 直查 sync_events 表。</p>
 */
public interface SyncEventSeqQuery {

    /**
     * 用户最新事件序号（无事件时返回 0）。
     */
    long latestSeq(UUID userId);
}
