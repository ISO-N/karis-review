# ADR-004: Review 评分链路保持强一致边界

## Status
已接受

## Context
评分 = 状态变更 + 排期计算 + 队列插入，必须原子；跨设备冲突靠乐观锁
（review_version + PESSIMISTIC_WRITE）解决。

## Decision
Review 的评分/同步/冲突解决永不分拆为独立服务；跨设备一致性通过乐观锁保持。
同步协议（sync）作为 Review 上下文的对外协议保留在核心单体。

## Consequences
- 更容易：无分布式事务；一致性逻辑简单可推理
- 更难：单点事务吞吐受限于单库（用读副本与缓存缓解读压力）
