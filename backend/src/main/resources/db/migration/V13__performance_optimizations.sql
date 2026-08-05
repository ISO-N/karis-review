-- =============================================================================
-- V13: 数据库性能优化（提案版）
-- 适用于: PostgreSQL 16 / karis_review
-- 说明:
--   1. Flyway 默认在事务内执行迁移，因此这里用普通 CREATE INDEX（非 CONCURRENTLY）。
--      若生产环境 cards / review_logs 表已很大（>1000 万行），请改用 psql 手动执行
--      CREATE INDEX CONCURRENTLY（不能在事务块内执行），避免锁表。
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. 索引优化
-- -----------------------------------------------------------------------------

-- 1.1 卡片列表/分页: WHERE deck_id = ? ORDER BY created_at [ASC|DESC] LIMIT ?
--     同时服务于 "all / new / learning" 三种筛选的分页排序，以及 bootstrap 全量拉取。
--     注意: PostgreSQL 索引可反向扫描，无需单独建 DESC 索引。
CREATE INDEX IF NOT EXISTS idx_cards_deck_created
    ON cards (deck_id, created_at);

-- 1.2 用户级新卡队列 + 统计（Index Only Scan）
--     服务: findNewCards / countNewByUserId / countByStageGrouped /
--           countByUserIdAndStageGreaterThanEqual / countByUserIdAndStageLessThan
CREATE INDEX IF NOT EXISTS idx_cards_user_stage_learning
    ON cards (user_id, stage, learning_mode, created_at);

-- 1.3 卡组到期列表: WHERE deck_id = ? AND next_review_date <= ? ORDER BY next_review_date
CREATE INDEX IF NOT EXISTS idx_cards_deck_due
    ON cards (deck_id, next_review_date)
    WHERE next_review_date IS NOT NULL;

-- 1.4 用户重学队列: WHERE user_id = ? AND learning_mode AND next_review_date <= ?
CREATE INDEX IF NOT EXISTS idx_cards_user_learning_due
    ON cards (user_id, next_review_date)
    WHERE learning_mode AND next_review_date IS NOT NULL;

-- 1.5 review_logs 按卡组统计: countReviewedTodayForDeck 的 semi-join 加速
CREATE INDEX IF NOT EXISTS idx_review_logs_user_card
    ON review_logs (user_id, card_id);

-- -----------------------------------------------------------------------------
-- 2. 触发器优化: 去掉非 users 表上 INSERT/UPDATE 的 users 点查
--    ⚠️ 已知缺陷：DELETE FROM users 的级联删除会在用户行删除后执行子表 AFTER DELETE
--    触发器，此时写 sync_events 违反外键。修复见 V14。
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION record_sync_event() RETURNS trigger AS $$
DECLARE
    target_user_id UUID;
BEGIN
    IF TG_TABLE_NAME = 'users' THEN
        IF TG_OP = 'DELETE' THEN
            target_user_id := OLD.id;
        ELSE
            target_user_id := NEW.id;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM users WHERE id = target_user_id) THEN
            RETURN COALESCE(NEW, OLD);
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        target_user_id := OLD.user_id;
    ELSE
        target_user_id := NEW.user_id;
    END IF;

    INSERT INTO sync_events (user_id, entity_type, entity_id, event_type)
    VALUES (
        target_user_id,
        TG_TABLE_NAME,
        COALESCE(OLD.id, NEW.id),
        CASE TG_OP
            WHEN 'INSERT' THEN 'CREATED'
            WHEN 'UPDATE' THEN 'UPDATED'
            ELSE 'DELETED'
        END
    );

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------------------------------------
-- 3. 数据清理（一次性；后续由应用层 @Scheduled 定期执行）
-- -----------------------------------------------------------------------------

DELETE FROM sync_events WHERE occurred_at < NOW() - INTERVAL '60 days';
DELETE FROM email_verification_codes WHERE expires_at < NOW() - INTERVAL '7 days';
DELETE FROM backup_snapshots b
USING (
    SELECT id, ROW_NUMBER() OVER (
        PARTITION BY user_id ORDER BY created_at DESC
    ) AS rn
    FROM backup_snapshots
) ranked
WHERE b.id = ranked.id AND ranked.rn > 7;

-- 4. 统计信息刷新
ANALYZE cards;
ANALYZE review_logs;
ANALYZE sync_events;
