# ADR-007: 统计预聚合（日级汇总）

## Status
已接受（阶段一落地，V13 迁移 + DailyReviewStatsService）

## Context
overview/trend 每次实时扫描 review_logs，数据量增长后查询变慢（G5）；
且统计为纯读，适合异步化。

## Decision
新增 daily_review_stats 预聚合表（user × 业务日 × deck，含全量行），
双通道维护：REVIEW_LOGGED Outbox 事件增量 upsert + 每日 04:30 全量重算兜底（幂等）。
查询优先读预聚合，缺失时回退实时（保证部署/测试环境一致）。

## Consequences
- 更容易：趋势/概览查询耗时与数据量解耦；统计模块可独立演进为 Analytics 服务
- 更难：口径需与实时查询对齐（事件增量 + 全量重算双重校验）；
      当日统计有秒级延迟（由 Outbox 轮询间隔决定）
