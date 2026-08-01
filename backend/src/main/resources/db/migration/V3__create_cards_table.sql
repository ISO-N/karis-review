CREATE TABLE cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deck_id UUID NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    front TEXT NOT NULL,
    back TEXT NOT NULL,
    stage INTEGER NOT NULL DEFAULT 0,
    consecutive_familiar INTEGER NOT NULL DEFAULT 0,
    next_review_date DATE NULL,
    learning_mode BOOLEAN NOT NULL DEFAULT FALSE,
    reentry_stage INTEGER NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_cards_deck_id ON cards(deck_id);
CREATE INDEX idx_cards_user_id ON cards(user_id);
CREATE INDEX idx_cards_next_review ON cards(user_id, next_review_date) WHERE next_review_date IS NOT NULL;