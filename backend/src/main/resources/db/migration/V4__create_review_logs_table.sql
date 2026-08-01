CREATE TABLE review_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating VARCHAR(10) NOT NULL CHECK (rating IN ('FORGET', 'VAGUE', 'FAMILIAR')),
    stage_before INTEGER NOT NULL,
    stage_after INTEGER NOT NULL,
    reviewed_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_review_logs_card_id ON review_logs(card_id);
CREATE INDEX idx_review_logs_user_id ON review_logs(user_id);
CREATE INDEX idx_review_logs_reviewed_at ON review_logs(user_id, reviewed_at);