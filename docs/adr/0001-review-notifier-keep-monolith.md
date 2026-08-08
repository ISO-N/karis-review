# ADR-0001: ReviewNotifier 保持单体，拆分评分链路 = 移动复杂度

- 状态：已接受（2026-08-08，架构评审候选 6 评估结论）
- 相关模块：`frontend/lib/review/providers/review_provider.dart`（618 行）、`frontend/lib/review/pages/review_page.dart`（1326 行）

## 背景

架构评审候选 6 提出：`ReviewNotifier` 同时管理远程/本地队列、分页、评分、重学插位、同步调度与 pending 计数，单次评分横跨 8+ 文件，建议"会话编排收敛为单一模块，UI 只消费窄接口"。

## 决策

**不拆分 `ReviewNotifier`。** 保留其为单体 StateNotifier，仅收敛 UI 进度自算（`ReviewSessionState.currentNumber`）。

## 备选方案与理由

- **拆分队列加载/评分/同步为独立类**——否决。`_loadLocalQueue`/`_rateRemote`/`_flushSync` 等已是私有方法，拆类只是换文件，且所有编排共享同一 `ReviewSessionState` 与 copyWith 语义，跨类传递状态反而扩大接口面。**删除测试不过：拆分后没有任何扩散点被删除，复杂度只是平移。**
- **UI 通过窄接口访问**——已满足。review_page 的 30 处访问全部是 `ref.watch(reviewProvider.select((s) => s.xxx))` 细粒度订阅，UI 只调公共方法（rate/flip/loadMore/removeStaleCard），状态变更加载式不可变（copyWith），不存在"UI 直接操控内部"。
- **进度计算集中**——采纳。`currentIndex + 1` 原由 UI 两处自算，收敛为 `ReviewSessionState.currentNumber` getter。

## 后果

- 正面：未来评审不会再重复建议拆分此 notifier；进度口径单一。
- 负面：`ReviewNotifier` 与 `review_page` 仍是大文件（618/1326 行），复杂度集中在两处，属可接受。
- 相关摩擦（proto 映射、排期公式、统计口径）已在架构评审候选 1/2/3/5 收敛，与本 ADR 不冲突。
