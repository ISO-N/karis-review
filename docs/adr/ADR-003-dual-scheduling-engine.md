# ADR-003: 排期算法双端实现，共享测试向量

## Status
已接受（现状确认）

## Context
离线评分需要本地排期，服务端与客户端行为必须完全一致（含逾期惩罚）。

## Decision
Java（SchedulingEngine）与 Dart（LocalSchedulingEngine）各维护一份公式相同的引擎，
用同一组测试向量双端验证；算法参数（Stage 间隔等）版本化。

## Consequences
- 更容易：离线体验完整；公式漂移可被测试向量捕获
- 更难：算法变更需双端同步修改；测试向量是唯一防线
