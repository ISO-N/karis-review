ALTER TABLE cards ADD COLUMN review_version BIGINT NOT NULL DEFAULT 0;

ALTER TABLE review_logs ADD COLUMN client_request_id VARCHAR(64) NULL;
CREATE UNIQUE INDEX idx_review_logs_user_client_request
    ON review_logs(user_id, client_request_id)
    WHERE client_request_id IS NOT NULL;

CREATE TABLE review_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    mode VARCHAR(10) NOT NULL CHECK (mode IN ('due', 'new')),
    deck_id UUID NULL REFERENCES decks(id) ON DELETE CASCADE,
    batch_size INTEGER NOT NULL DEFAULT 10,
    total_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_review_sessions_user_id ON review_sessions(user_id);
CREATE INDEX idx_review_sessions_expires_at ON review_sessions(expires_at);

CREATE TABLE review_queue_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES review_sessions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    position INTEGER NOT NULL,
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    CONSTRAINT uq_review_queue_session_position UNIQUE (session_id, position)
);

CREATE INDEX idx_review_queue_items_session_position
    ON review_queue_items(session_id, position);
CREATE INDEX idx_review_queue_items_user_id ON review_queue_items(user_id);
