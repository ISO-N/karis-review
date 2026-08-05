-- =============================================================================
-- V14: 修复 record_sync_event 触发器的级联删除外键问题
--
-- 背景：V13 优化触发器时移除了非 users 表上的 EXISTS 检查（依赖外键保证用户存在）。
--       但"DELETE FROM users"触发的级联删除会在用户行已删除后执行子表的 AFTER
--       DELETE 触发器，此时写入 sync_events 会违反 sync_events_user_id_fkey。
--
-- 修复：仅 DELETE 分支（含 users 表自身）保留 EXISTS 检查；INSERT/UPDATE 分支
--       有外键约束保证用户存在，保持零额外点查。
-- =============================================================================

CREATE OR REPLACE FUNCTION record_sync_event() RETURNS trigger AS $$
DECLARE
    target_user_id UUID;
BEGIN
    IF TG_TABLE_NAME = 'users' THEN
        target_user_id := COALESCE(OLD.id, NEW.id);
    ELSIF TG_OP = 'DELETE' THEN
        target_user_id := OLD.user_id;
    ELSE
        target_user_id := NEW.user_id;
    END IF;

    -- 级联删除场景（DELETE FROM users 级联删除 decks/cards/review_logs）下，
    -- 子表 DELETE 触发器执行时用户行可能已被删除，必须确认用户仍存在；
    -- INSERT/UPDATE 分支由外键保证用户存在，无需额外点查。
    IF TG_TABLE_NAME = 'users' OR TG_OP = 'DELETE' THEN
        IF NOT EXISTS (SELECT 1 FROM users WHERE id = target_user_id) THEN
            RETURN COALESCE(NEW, OLD);
        END IF;
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
