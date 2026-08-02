CREATE TABLE sync_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    entity_type VARCHAR(20) NOT NULL,
    entity_id UUID NOT NULL,
    event_type VARCHAR(10) NOT NULL CHECK (event_type IN ('CREATED', 'UPDATED', 'DELETED')),
    event_seq BIGSERIAL NOT NULL,
    occurred_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_sync_events_seq ON sync_events(event_seq);
CREATE INDEX idx_sync_events_user_seq ON sync_events(user_id, event_seq);

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

    IF EXISTS (SELECT 1 FROM users WHERE id = target_user_id) THEN
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
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_decks_sync
    AFTER INSERT OR UPDATE OR DELETE ON decks
    FOR EACH ROW EXECUTE FUNCTION record_sync_event();

CREATE TRIGGER trg_cards_sync
    AFTER INSERT OR UPDATE OR DELETE ON cards
    FOR EACH ROW EXECUTE FUNCTION record_sync_event();

CREATE TRIGGER trg_review_logs_sync
    AFTER INSERT OR UPDATE OR DELETE ON review_logs
    FOR EACH ROW EXECUTE FUNCTION record_sync_event();

CREATE TRIGGER trg_users_sync
    AFTER INSERT OR UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION record_sync_event();
