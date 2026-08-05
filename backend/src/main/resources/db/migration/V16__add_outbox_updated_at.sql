-- V16: 为 outbox_events 补充 updated_at 列（重试/死信清理的时间依据）
ALTER TABLE outbox_events ADD COLUMN updated_at TIMESTAMP NOT NULL DEFAULT NOW();
