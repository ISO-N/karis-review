-- 学习来源：标记进入学习模式（重学）时卡片所属的阶段。
-- NEW   = 学新阶段（新卡）忘记/模糊进入重学 → 重学卡归学新队列
-- REVIEW = 复习阶段（到期卡）忘记/模糊进入重学 → 重学卡归复习队列
-- NULL  = 非重学状态，或历史数据（旧数据按 REVIEW 处理，保持原行为）
ALTER TABLE cards ADD COLUMN learning_origin VARCHAR(10);

-- review_logs 记录评分时刻卡片的 learning_origin 快照，
-- 用于统计时区分「复习阶段的重学评分」（计入今日复习）与
-- 「学新阶段的重学评分」（不计入今日复习）。
ALTER TABLE review_logs ADD COLUMN learning_origin VARCHAR(10);
