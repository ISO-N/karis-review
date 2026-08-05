# ADR-001: 保持模块化单体，不采用微服务起步

## Status
已接受（本 ADR 将现有架构决策显式化，见 architecture-roadmap.md）

## Context
团队规模小、产品早期、领域边界仍随需求演进。现有代码已是模块化单体：
11 个业务模块、`controller → service → repository` 单向依赖、严禁循环依赖、
排期算法（SchedulingEngine）为零依赖纯算法类。

## Decision
以模块化单体作为长期目标架构形态。模块边界升级为显式契约
（ArchUnit 依赖规则 + 模块 API 清单 + IdentityPort 门面），
仅在 ADR-002 的触发条件下拆分具体上下文。

## Consequences
- 更容易：迭代快、部署简单、事务一致、无分布式复杂度
- 更难：依赖纪律需要机器检查维持（ArchUnit）；独立扩缩容受限
- 回退路径：模块契约保留"手术缝线"，按需拆分无需重构
