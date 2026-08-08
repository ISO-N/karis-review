# CONTEXT.md — Karis Review 领域词汇表

领域语言给「好的接缝」命名。架构评审（improve-codebase-architecture）与代码设计（codebase-design）使用本文件的术语，不用「组件/服务/API/边界」等漂移词。

## 领域术语

| 术语 | 定义 | 备注 |
|---|---|---|
| 卡组 Deck | 卡片的分组容器 | 实体 `deck` |
| 卡片 Card | 正反面内容的复习单元，带排期状态 | 实体 `card` |
| 复习 Review | 对卡片的评分会话，产生评分记录 | 模块 `review` |
| 评分 Rating | FORGET / VAGUE / FAMILIAR 三档 | 见 `Rating` 枚举（收敛中） |
| 重学 Relearning | 忘记/模糊后进入的连续复习模式（learning_mode） | 需连续 3/5 次 Familiar 脱离 |
| 学新队列 NewQueue | 待学新卡 + `NEW` 来源重学卡 | 归属见下 |
| 复习队列 DueQueue | 到期卡 + `REVIEW` 来源重学卡 | 归属见下 |
| 学习来源 LearningOrigin | 重学卡进入重学时所属阶段：`NEW`（学新阶段）或 `REVIEW`（复习阶段），非重学为 null | 队列归属与统计口径的依据 |
| 今日 Today | 不是自然日；以用户 refresh_time（默认 04:00）为边界的业务日 | 权威实现 `DateUtils.calculateToday` / 前端 AppDateUtils |
| 刷新点 RefreshTime | 每日刷新时间，业务日边界 | 默认 `04:00:00`（收敛到单一数据源中） |
| 排期状态 SchedulingState | 卡片排期字段的值对象投影（stage/consecutive_familiar/next_review_date/learning_mode/reentry_stage/learning_step/learning_origin/review_version） | 四类出口统一取数 |
| 逾期惩罚 | VAGUE 评分时按遗忘曲线估算等效 stage 的降级逻辑 | 前后端公式一致 |
| 插位 Interleave | 重学卡按 2^n 间距插入队列的规则 | 前端 QueueComposer / 后端 QueueInterleaver |
| 今日复习 reviewedToday | 今日非新学阶段的重学评分计数 | 口径谓词单一源 |
| 今日新学 learnedToday | 今日新卡上的 FAMILIAR 计数 | 同上 |
| 今日任务 TodayTasks | 复习队列 + 学新队列的合并口径（今日页记忆刻度） | 在 due_stage_distribution 基础上并入学新 |
| 快照导出 Bootstrap | 全量同步载荷 | 含全部实体与排期状态 |
| 增量同步 Delta | 基于 event_cursor 的增量载荷 | 触发器写 sync_events |
| 幂等键 ClientRequestId | 评分同步的去重键 | 备份恢复需保留 |
| 备份 Backup | 用户全量 JSON 导出/导入 | 需 format_version（收敛中） |

## 架构词汇（评审/设计共用）

- **模块**：能独立理解与变更的边界（不是「服务/组件」）。
- **接口**：模块对外承诺，是测试面。
- **深度**：接口相对实现吸收的复杂度比例；深模块 = 接口小、实现重。
- **接缝**：可替换依赖的边界；一个适配器 = 假设的接缝，两个 = 真实。
- **适配器**：把外部依赖接到领域接口上的模块。
- **杠杆**：改一处提升全局；高杠杆 = 单一事实源。
- **局部性**：理解一个概念所需弹跳的模块数；局部性好 = 概念与实现在一起。
- **删除测试**：删除某抽象是否会集中复杂度（好）还是只搬运（坏）。

## 已收敛的事实源（架构评审历轮）

| 事实 | 单一实现 | 备注 |
|---|---|---|
| 排期公式/间隔表/maxStage/阈值 | 后端 `SchedulingEngine` / 前端 `scheduling_constants.dart` | 跨语言双份，需等价性测试向量（深化中） |
| 队列插位 | 后端 `QueueInterleaver` / 前端 `QueueComposer` | 跨语言对应实现 |
| due/new 谓词 | 后端 `CardQueryPredicates` / 前端 `_isDueCard`/`_isNewCard` | 拆分支常量 |
| 统计谓词 | 后端 `ReviewLogQueryPredicates` / 前端 `offline_stats` | 含 getTrend（修复中） |
| 排期状态投影 | `SchedulingState` 值对象 | 四出口 round-trip |
| 评分管道 | `ReviewService.rateSingle` | 幂等/版本判定收敛 |
| proto 映射 | 前端 `proto_mappers` 声明式投影 | 漏字段测试期红 |
| 数据刷新编排 | 前端 `DataRefreshController` + `dataVersionProvider` | 加载骨架收敛中 |
| 卡片映射 | 前端 `offline_mappers` | 反向映射补齐中 |
| 刷新点解析 | 后端 `UserRefreshTime.resolve` | 跨模块适配器收敛中 |
| 业务日期 | `DateUtils`（禁第三种写法） | 实体层时钟收敛中 |

## 深化中的新模块/术语（2026-08-08 第三轮评审 grilling）

- **跨语言测试向量**：语言无关的排期/统计用例数据（如 `scheduling-vectors.json`），两端测试读同一份。**已落地**：`docs/design/scheduling-vectors.json`（26 条），后端 `SchedulingVectorsTest` 与前端 `scheduling_vectors_test.dart` 同源断言。
- **BusinessTodayService**（后端）：把「读刷新点 → 算今天」收敛为业务模块可依赖的适配器，取代跨模块注入 `UserRepository`。**已落地**：`UserRefreshTimeQuery` 接口 + `UserRefreshTimeService`（30s TTL 缓存），review/card/stats 不再持有 auth 的 repository。
- **ServerErrorReporter**（后端）：common 包内错误上报接口，log 模块实现，切断 common↔log 环。**已落地**。
- **BackupCodec**（后端）：备份 JSON schema 读写纯模块，BackupService 只做编排。**待做**（P5 未排入本轮）。
- **DualChannelLoader**（前端）：Card/Deck/Stats Notifier 共用的在线/离线双通道加载骨架。**已落地**：`shared/providers/dual_channel_loader.dart`（Card/Deck 收敛，Stats 的 TTL/inFlight 刻意不并入）。
- **Rating 枚举**（前端）：FORGET/VAGUE/FAMILIAR 单一事实，消灭跨层字符串字面量。**已落地**：`shared/scheduling/rating.dart`（常量类，DB/API 线格式不变）。
- **rating_labels 纯函数**（前端）：复习页评分文案/键盘映射/间隔标签。**已落地**：`review/models/rating_labels.dart` + `rating_labels_test.dart`。
- **KarisSearchField**（前端）：卡片/卡组列表共用的防抖搜索组件。**待做**（P5 未排入本轮）。
- **CardContentFormat**（前端）：Delta/Markdown 内容格式检测与解析的单一入口，渲染与 TTS 共用。**待做**（P5 未排入本轮）。
- **AppDefaults**（前端）：跨层共享默认值（默认刷新点 `04:00:00`）的单一数据源。**已落地**：`SchedulingConstants.defaultRefreshTime`（13 处魔数收敛）。
- **PagingHelper / EtagSupport**（后端）：分页 clamp 与 ETag 匹配统一工具。**已落地**（common/util + common/etag）。
- **时钟统一**（后端 B3）：实体/验证码/调度全部走 `DateUtils.now()`（业务时区）。**已落地**（8 文件）。
- **待更新文档**：CLAUDE.md、docs/design/database.md、docs/design/api.md（迁移/字段/示例对账）。**已落地**（A7 文档对账）。
