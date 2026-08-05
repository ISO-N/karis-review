# ADR-002: 优先拆分候选为 Identity 与 Analytics

## Status
已接受

## Context
认证流量（登录/注册/发码）特征为高频、突发、可独立限流；统计查询为纯读，
数据可由事件流异步化。两者与核心业务（复习/排期）的耦合点少。

## Decision
阶段二优先拆分 Identity（身份认证）与 Analytics（统计洞察）。
Review/Content/Scheduling 留在核心单体（强一致事务边界）。
拆分触发条件：十万级用户 / 独立扩缩容需求 / 团队规模可维护多服务。

## Consequences
- 更容易：独立扩缩容；Analytics 解耦后核心库读负载下降
- 更难：引入跨服务通信（Outbox 事件流）与部署复杂度
- 已铺垫：IdentityPort 门面（M6）、Outbox 事件总线 + HttpExternalEventPublisher（M7）
