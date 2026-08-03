CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX idx_cards_front_search_trgm
    ON cards USING gin (lower(front) gin_trgm_ops);
CREATE INDEX idx_cards_back_search_trgm
    ON cards USING gin (lower(back) gin_trgm_ops);
