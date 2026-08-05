-- V15: 可靠性基建 —— Outbox 事件表 / 每日统计预聚合 / 备份快照元数据

-- ============================================================
-- 1. outbox_events：可靠异步事件投递（邮件、统计增量、外部事件流）
--    与业务同事务写入，由 OutboxRelay 轮询投递，支持重试与死信。
-- ============================================================
CREATE TABLE outbox_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_type VARCHAR(64) NOT NULL,          -- 事件所属聚合类型（如 card / review_log / user）
    aggregate_id UUID,                            -- 聚合 ID（可空：全局事件）
    event_type VARCHAR(128) NOT NULL,             -- 事件类型（如 REVIEW_LOGGED / MAIL_RESET_CODE）
    payload JSONB NOT NULL,                       -- 事件载荷（业务数据）
    status VARCHAR(16) NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'PROCESSED', 'DEAD')),
    attempts INTEGER NOT NULL DEFAULT 0,          -- 已投递尝试次数
    max_attempts INTEGER NOT NULL DEFAULT 10,     -- 最大尝试次数（超过进入 DEAD）
    next_attempt_at TIMESTAMP NOT NULL DEFAULT NOW(),  -- 下次投递时间（指数退避）
    last_error TEXT,                              -- 最近一次投递错误信息
    locked_at TIMESTAMP,                          -- 投递中加锁时间（并发保护）
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMP
);

CREATE INDEX idx_outbox_status_attempt ON outbox_events(status, next_attempt_at);
CREATE INDEX idx_outbox_created ON outbox_events(created_at);
CREATE INDEX idx_outbox_aggregate ON outbox_events(aggregate_type, aggregate_id);

-- ============================================================
-- 2. daily_review_stats：按 (用户 × 业务日 × 卡组) 预聚合复习统计
--    趋势/概览查询改为读本表，与 review_logs 数据量解耦。
--    deck_id 为 NULL 的行表示用户当日全量汇总。
-- ============================================================
CREATE TABLE daily_review_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    stat_date DATE NOT NULL,                      -- 业务日期（基于 refresh_time 的"今天"）
    deck_id UUID,                                 -- NULL = 用户全量汇总行
    reviewed_count INTEGER NOT NULL DEFAULT 0,    -- 复习次数（非新卡）
    learned_count INTEGER NOT NULL DEFAULT 0,     -- 新学次数（新卡 FAMILIAR）
    unique_cards INTEGER NOT NULL DEFAULT 0,      -- 当日复习去重卡片数
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, stat_date, deck_id)
);

CREATE INDEX idx_daily_stats_user_date ON daily_review_stats(user_id, stat_date DESC);

-- 用户全量汇总行（deck_id IS NULL）的唯一性：PostgreSQL 中 NULL 不参与普通唯一约束，
-- 用部分唯一索引保证同一用户同一日期只有一行全量汇总。
CREATE UNIQUE INDEX idx_daily_stats_user_date_all
    ON daily_review_stats(user_id, stat_date) WHERE deck_id IS NULL;

-- ============================================================
-- 3. backup_snapshots 改造：快照数据外置对象存储，库内仅存元数据
--    data 列保留（兼容旧记录/本地模式），新增 storage 元数据列。
-- ============================================================
ALTER TABLE backup_snapshots ALTER COLUMN data DROP NOT NULL;
ALTER TABLE backup_snapshots ADD COLUMN storage_key VARCHAR(512);
ALTER TABLE backup_snapshots ADD COLUMN storage_size BIGINT;
ALTER TABLE backup_snapshots ADD COLUMN storage_sha256 VARCHAR(64);
ALTER TABLE backup_snapshots ADD COLUMN storage_status VARCHAR(16) NOT NULL DEFAULT 'LOCAL'
    CHECK (storage_status IN ('LOCAL', 'OBJECT_STORAGE'));

-- ============================================================
-- 4. email_verification_codes 与 outbox 数据保留策略
--    验证码过期清理：保留最近 7 天（由 ApplicationCleanupTask 执行）
--    outbox_events 已处理记录保留 7 天，DEAD 保留 30 天（由 OutboxCleanupTask 执行）
-- ============================================================
