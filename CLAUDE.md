# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Karis Review 是一个极简、专注的间隔重复闪卡复习应用（前后端分离）。所有文档均为中文，注释与 UI 文案也使用中文。

## 常用命令

### 数据库（PostgreSQL 16，docker compose）

```bash
docker compose up -d postgres
```

数据库 `karis_review`，账号/密码均为 `postgres`，端口 5432。配置见 `backend/src/main/resources/application.properties`。

### 后端（Spring Boot 3.4 + Java 21 + Maven）

```bash
cd backend
mvn spring-boot:run        # 启动，默认 http://localhost:8080/api
mvn spring-boot:run -Dspring-boot.run.profiles=dev  # 开发模式，Swagger UI 在 /swagger-ui.html
mvn test                   # 全部测试
mvn test -Dtest=SchedulingEngineTest   # 单个测试类
```

启动后端前必须先启动 PostgreSQL。测试分三层：纯单元/部件测试（SchedulingEngineTest、SchedulingVectorsTest、QueueInterleaverTest、Service/Controller 测试等，无需数据库）、Spring 上下文加载测试（`KarisreviewApplicationTests`，需要数据库）、真实 PostgreSQL + HTTP 系统测试（含日志、会话分页、同步失效和数据量冒烟；只创建/清理 `system-test-*@example.com` 用户）。详见 `docs/design/testing.md`。

### 前端（Flutter + Riverpod + GoRouter）

```bash
cd frontend
flutter pub get
flutter run -d chrome      # 开发运行（连接 localhost 后端）
flutter test               # 测试
flutter analyze            # 静态分析
```

生产构建需指定 API 地址（默认是 `http://localhost:8080/api`，通过 `String.fromEnvironment('API_BASE_URL')` 注入）：

```bash
flutter build web --release --dart-define=API_BASE_URL=https://review.kariscode.top/api
```

Android release 包名为 `top.kariscode.karisreview`，debug 包名为 `top.kariscode.karisreview.debug`，两者可同一设备共存；debug 应用名带 `Debug` 后缀，并允许 HTTP 明文访问本地 API。

## 架构总览

前后端分离：Flutter 客户端只做 UI 渲染，无本地业务数据存储；服务端无状态，认证靠 JWT（`Authorization: Bearer <token>`，7 天有效）。Android release 包名 `top.kariscode.karisreview`，debug 包名 `top.kariscode.karisreview.debug`，生产环境 `https://review.kariscode.top/api`。详细设计文档见 `docs/`（architecture.md、api.md、database.md）。

### 后端（backend/src/main/java/top/kariscode/karisreview/）

按业务模块分包（`auth`、`deck`、`card`、`review`、`stats`、`backup`、`settings`），每个模块内部单向依赖 `controller → service → repository`。模块间严禁循环依赖：`card → deck`、`review → card/deck`、`stats → review/deck`、`backup` 依赖全部模块；**`deck → stats` 仅 service 层**（`DeckService` 调 `StatsService.getDeckCounters` 取卡组计数，包级无环，2026-08 架构评审候选 4）。

关键点：

- **用户身份获取**：`JwtAuthenticationFilter`（`config/`）解析 Token 后把 `UUID userId` 放进 `SecurityContextHolder`；Controller 用 `@AuthenticationPrincipal UUID userId` 拿到当前用户。所有业务查询都以 `userId` 过滤，实体用 `UUID` 外键字段（如 `card.getDeckId()`）而非 JPA 关联对象。
- **注册邀请码**：`auth.invite.enabled` 与 `auth.invite.code` 控制，默认关闭；开启时注册必须先通过邀请码校验，前端通过公开 `GET /api/auth/config` 获取 `invite_code_required` 决定是否显示输入框。
- **邮箱验证码**：注册与找回密码共用验证码机制（`PasswordResetCodeService` + `email_verification_codes` 表，V12 迁移）。验证码 6 位数字、15 分钟有效、同邮箱同用途 60 秒冷却、最多 10 次尝试，比较用常量时间算法。发送走 `MailSender` 抽象：未配置 `mail.smtp.host` 时 `NoopMailSender` 只打日志；配置后 `SmtpMailSender` 真实发送，支持 `mail.smtp.socks.host/port` 走本地 SOCKS5 代理（境外 SMTP 服务在国内部署时使用）。端点：`POST /api/auth/register-code`（注册发码，邮箱已注册报 400）、`POST /api/auth/password/reset-code`（找回发码，邮箱不存在也返回成功防枚举）、`POST /api/auth/password/reset`（校验验证码并重置密码）、`PUT /api/auth/password`（已登录改密，需当前密码，成功后前端主动登出）。
- **统一响应**：所有接口返回 `common/dto/ApiResponse`（`code`/`message`/`data`）；业务错误抛 `BusinessException(code, message)`，由 `common/exception/GlobalExceptionHandler` 统一处理。
- **权限边界**：`SecurityConfig` 放行 `/api/auth/config`、`/api/auth/register`、`/api/auth/login` 以及 OpenAPI 文档路径（`/v3/api-docs/**`、`/swagger-ui/**`、`/swagger-ui.html`），其余全部要求认证。跨域配置在 `CorsConfig`（全放开）。
- **API 文档**：集成 Springdoc OpenAPI 3，配置了 JWT Bearer 安全方案；登录/注册/注册配置接口豁免认证要求，生产 profile 关闭文档。
- **权限边界**：`SecurityConfig` 放行 `/api/auth/register`、`/api/auth/login` 以及 OpenAPI 文档路径（`/v3/api-docs/**`、`/swagger-ui/**`、`/swagger-ui.html`），其余全部要求认证。跨域配置在 `CorsConfig`（全放开）。
- **API 文档**：集成 Springdoc OpenAPI 3，配置了 JWT Bearer 安全方案；登录/注册接口豁免认证要求，生产 profile 关闭文档。
- **"今天"的定义**：不是自然日。`common/util/DateUtils.calculateToday(refreshTime)` 依据用户设置的 `refresh_time`（默认 04:00）计算"今天"范围——当前时间在刷新点之前时算前一天。**刷新点解析统一走 `auth/util/UserRefreshTime.resolve`（兜底 04:00 单一实现，2026-08 架构评审候选 4）**。业务时区全局固定为 `app.timezone`（默认 `Asia/Shanghai`，UTC+8），前端离线排程同样按该时区计算；`server_time` 仍为 UTC。所有到期判断（due、stats、学习模式插入位置）都基于此。
- **数据库变更**：`ddl-auto=none`，schema 由 Flyway 迁移管理（`src/main/resources/db/migration/V1~V15`，清单以 docs/design/database.md §4 为准）。改表必须新增迁移脚本，不能改已提交的脚本。
- **统计口径**：`review_logs.is_new_card` 标记评分时是否为 Stage 0 且非重学的新卡；`learning_origin`（cards/review_logs，V15 迁移）标记重学卡来源——学新阶段（新卡）忘记进入重学为 `NEW`，复习阶段（到期卡）忘记/模糊为 `REVIEW`，非重学为 null（历史重学数据按 `REVIEW` 处理）。**队列归属按来源定**：学新队列 = 待学新卡 + `NEW` 重学卡；复习队列 = 到期卡 + `REVIEW` 重学卡（`buildNewQueue`/`buildDueQueue`，本地 `getNewQueue`/`getDueQueue` 一致）。**今日复习不含新学**：`reviewed_today` 统计今日 `is_new_card=false` 且 `learning_origin <> 'NEW'` 的评分（即到期卡复习 + 复习阶段重学，学新阶段的重学评分不计入）；今日新学只统计新卡上的 FAMILIAR；`due_today`（待复习）与 `due_stage_distribution` 统计已排期（`next_review_date` 非空且 ≤ 今日）且非 `NEW` 重学的卡，不含未学新卡与学新阶段重学卡；今日页记忆刻度在 `due_stage_distribution` 基础上把 `new_cards`（含 `NEW` 重学卡，即学新队列规模）并入 stage 0，口径 = 今日任务（复习队列 + 学新队列）。**注意**：日志经 protobuf 同步时，`proto_mappers.dart` 的 `reviewLogToMap` 必须携带 `learning_origin`（曾有漏映射导致本地统计把学新重学计入今日复习，复盘见 docs/design/architecture.md §7.1.2）。**2026-08-08 起该映射已机制化**：`shared/proto/proto_mappers.dart` 为声明式投影——键集合由生成代码 `info_.byIndex` 推导（新增 proto 字段自动进入映射，不手写字面量键），值函数对未处理字段抛 `UnsupportedError`，字段对账测试（`frontend/test/proto_mappers_test.dart`）保证加字段漏映射在测试期红；新增同步字段只需在对应值函数补一行。**due/new 口径谓词已单一化**（2026-08-08 架构评审候选 3）：后端集中在 `card/repository/CardQueryPredicates`（JPQL/SQL 双变体），`CardRepository` 的 `@Query` 全部拼接该常量；前端离线过滤收敛为 `OfflineRepository._isNewCard/_isDueCard`；改口径必须两端同步。**2026-08-08 第二轮评审闭合**：`CardQueryPredicates` 拆分支常量（`DUE_BASE`/`DUE_RELEARNING`/`NEW_BASE`/`NEW_RELEARNING`），四个队列查询（findDueCards/findLearningModeCardsForReview/findNewCards/findLearningModeCardsForNew）全部拼接分支常量；卡列表 `getFilteredFlashCards` 的 `due`/`new` 筛选直接委托 `_isDueCard`/`_isNewCard`（此前手写谓词：due 漏排除学新重学卡、new 漏含 NEW 重学卡，与计数口径不一致——重学卡 `next_review_date` 恒为评分当天，`nextReviewDate<=today` 必然命中）。**统计侧同步收敛**：`review/repository/ReviewLogQueryPredicates` 集中「今日复习/今日新学」口径（JPQL/native SQL 双变体），`ReviewLogRepository` 的 countReviewedToday/countReviewedTodayForDeck/findDailyTrend/countLearnedToday 全部引用；`StatsService.getDeckStats` 复用 `getDeckCounters` 补字段、分布累加收敛 `accumulateStage`。
- **卡片快捷导入**：`card/service/CardImportParser` 负责解析 JSON 数组，`CardImportService` 校验卡组归属并批量写入新卡；`CardImportController` 暴露 `/api/decks/{deckId}/cards/import/preview` 与 `/api/decks/{deckId}/cards/import`，不写复习记录和排期状态；导入响应携带 `imported_card_ids`，卡片列表支持 `new` 筛选与 `/api/cards/batch-delete` 批量删除。列表接口 `GET /api/decks/{deckId}/cards` 支持 `q` 参数按正反面即时搜索，与现有筛选叠加，`%`、`_`、`\` 按字面值转义。

#### 排期算法（核心业务逻辑）

`review/service/SchedulingEngine.java` 是零依赖的纯算法类（便于单测），`ReviewService` 负责编排。**前端排期常量与公式单一数据源**：`shared/scheduling/scheduling_constants.dart`（间隔表 / maxStage / 3·5 阈值 / familiar·vague 间隔公式 / 2^n 插位偏移），`LocalSchedulingEngine` 与 `ReviewCard` 委托其公式，UI（`theme.dart`）不持有业务常量（2026-08 架构评审候选 5）；与后端为跨语言独立副本，改公式必须两端同步。**跨语言等价性由测试机制保证**（2026-08-08 架构评审 A1）：`docs/design/scheduling-vectors.json` 是语言无关的排期测试向量单一事实源（26 条，覆盖 FAMILIAR/FORGET/VAGUE/逾期惩罚/来源归属），后端 `SchedulingVectorsTest` 与前端 `scheduling_vectors_test.dart` 读同一份向量断言——**改公式必须：1) 改向量文件；2) 两端测试同绿**：

- **Stage 0-8**，间隔为 `{0, 1, 2, 4, 7, 15, 30, 90, 180}` 天。
- **FAMILIAR**：非重学模式升级 1 级；Stage 0 → 1（1 天后）。
- **FORGET**：重置 Stage 0 并进入重学模式（`learning_mode=true`），需连续 5 次 Familiar 才脱离（回 Stage 1）。
- **VAGUE**：降 1 级并进入重学模式，`reentry_stage` 记录目标级别，只需连续 3 次 Familiar 脱离并回到该级别（复习间隔 = 该级间隔 − 上一级间隔）；Stage 1 的 VAGUE 视同 FORGET。
- **逾期惩罚**：VAGUE 评分时按遗忘曲线估计等效 stage——逾期率 ρ = (间隔+逾期天数)/间隔，降级数 k = floor(log₂(ρ))，等效 stage = max(1, stage−k)，从等效 stage 回退 1 级并以其为 reentry 目标；逾期 ≤ 2 天或 ρ < 2 免罚；FAMILIAR/FORGET 不受逾期影响。前后端公式一致（`SchedulingEngine.calculateEffectiveStage` 与 `LocalSchedulingEngine.calculateEffectiveStage`）。
- **重学插入**：重学中的卡片按 `learning_step`（2^n 间距）插入所属队列（第 1 次隔 1 张、第 2 次隔 2 张、第 3 次隔 4 张……）。**插位单一实现**（2026-08-08 架构评审 F1）：后端 `review/service/QueueInterleaver.interleave`（零依赖纯模块，可独立单测），前端 `shared/scheduling/queue_composer.dart` 的 `QueueComposer.interleave`（baseOffset 区分离线重建=0 与会话内插回=已消费 currentIndex），`ReviewService` 队列构建与 `OfflineRepository.getNewQueue`/`getDueQueue`、`review_provider._reinsertRelearningCard` 全部走单一实现，两端为跨语言对应版本。**重学卡按 `learning_origin` 归属队列**：学新阶段忘记（`NEW`）归学新队列，复习阶段忘记/模糊（`REVIEW`）归复习队列；重学中再忘记/模糊保持原来源，脱离重学（连续 Familiar 达标）清除来源。前端会话内 `_reinsertRelearningCard` 按同规则把重学卡实时插回当前队列，退出重进后仍由队列按来源重建，两处行为一致。
- **到期队列排序**：逾期优先——按逾期天数（`calculateToday` − `next_review_date`）降序，同逾期天数内按 `next_review_date` 升序；服务端 `CardRepository.findDueCards` 与前端离线 `OfflineRepository.getDueQueue` 保持一致。重学卡不参与逾期排序。

`Card` 实体新增了 `learning_step`（V6）与 `learning_origin`（V15）字段，`review_logs` 也新增了 `learning_origin` 快照（V15）；数据库文档中的表结构需同步。**排期状态统一经 `card/entity/SchedulingState` 值对象投影**（2026-08 架构评审候选 2）：`Card.getSchedulingState()`/`applySchedulingState()`，CardResponse/ReviewCardResponse/BootstrapCard/备份 JSON 四类出口都从它取排期字段，禁止逐字段散落读取。**评分管道单一化**（2026-08-08 架构评审 B1）：`ReviewService.rateSingle` 是共享评分管道（幂等判定 `checkIdempotency` → 版本冲突判定 `isVersionConflict` → `computeRating`），`rateCard`（单卡出口，幂等重放不锁卡直接返回历史）与 `syncRatings`（批量出口）是同一管道的两个出口，禁止再各自实现幂等/冲突检查。

#### 备份（backup/）

- `BackupService.exportData`：导出用户全量数据（decks/cards/review_logs）为 JSON，同时存一份 `backup_snapshots` 快照。卡片排期状态经 `card/entity/SchedulingState` 值对象**全字段导出**（stage/consecutive_familiar/next_review_date/learning_mode/reentry_stage/learning_step/learning_origin，另带 review_version）——2026-08 架构评审候选 2 修复了曾漏导出 learning_step/learning_origin/review_version 导致恢复后队列归属退化与重学插位丢失的问题。**卡片与日志携带原 `card_id`**（2026-08-08 架构评审 B4：日志另保留 `card_front` 兼容旧版工具），`exported_at` 走 `DateUtils.now()`（业务时区）。
- `BackupService.importData`：**先删光该用户现有数据再导入**（不可逆）。导入的卡片获得新 ID，复习日志**按备份 `card_id` 直连恢复**（备份 id → 新 id 映射，同 front 多卡不再错挂；旧备份无 `card_id` 时回退 `card_front` 文本匹配兜底）；排期状态整体恢复（`SchedulingState.fromJson`，旧备份缺键自动回退默认）。
- `BackupScheduler`：`@Scheduled(cron = "0 10 4 * * *")` 每天 04:10 为所有用户做应用级备份（`SchedulingConfig` 开启调度）。

### 前端（frontend/lib/）

按业务模块分包，每个模块统一为 `repositories/`（Dio 调用）→ `providers/`（Riverpod StateNotifier，持有不可变 state 类）→ `pages/`（ConsumerWidget/ConsumerStatefulWidget）→ `models/`（序列化类）。

- **API 客户端**：`shared/api/api_client.dart` 的 Dio 单例，Token 内存缓存并持久化到 SharedPreferences；401 通过回调清 token、更新 Auth 状态并跳登录；GET 对连接/超时类错误做有限重试，并对稳定 GET 接口保存 ETag 复用 304。基础 URL 与端点常量在 `shared/api/api_endpoints.dart`。
- **传输优化**：服务端开启 gzip；同步/复习高流量接口支持同 URL Protobuf 内容协商（`Accept`/`Content-Type: application/x-protobuf`），默认仍为 JSON。协商失败（401/406/415）回退 JSON 的判定统一在 `shared/api/api_client.dart` 的 `isProtoUnsupported`（review/sync repository 共用，2026-08 架构评审候选 1 收敛）。**回退编排统一走 `ApiClient.getData`/`postData`**（2026-08-08 架构评审 F3）：proto 优先、协商失败自动回退 JSON 并取 `data['data']`，`sync_repository`/`review_repository` 只声明 `parse`（proto 解析）与 `toData`（消息转业务结构）——原 6 份逐方法回退骨架已删除；新增协商接口零样板。复习响应不再传输可由 `stage` 推导的间隔字段。
- **路由/鉴权**：`app/router.dart` 的 GoRouter 监听 `authProvider` 做重定向（未登录 → `/login`，已登录访问登录页 → `/decks`）。`/review/due` 与 `/review/new` 共用 `ReviewPage`，用 `filter` 参数区分学习/复习模式，卡组筛选走 `deck_id` query 参数。
- **富文本**：卡片正反面存 Quill Delta JSON 字符串（`flutter_quill` 编辑器，LaTeX 和代码块是自定义 custom block embed）。`shared/widgets/rich_card_content.dart` 渲染时自动识别——内容以 `[` 开头且可解析为 JSON 列表则按 Delta 渲染，否则按轻量 Markdown 解析（`**粗体**`、`*斜体*`、`` `行内代码` ``、`# 标题`、`- 列表`、`$$...$$` 行间公式、`$...$` 行内公式、` ``` 代码块 ````），并对 Delta/普通文本两种格式都做了容错处理。
- **卡片编辑**：`card/pages/card_editor_page.dart` 为独立页面，正面/反面通过分段切换编辑，不把两面同时堆在一个界面里。
- **卡片快捷导入**：`card/pages/card_import_page.dart` 为独立页面，支持粘贴 JSON 或选择 `.json` 文件；解析和最终导入都走后端，预览阶段可编辑/删除行，不支持新增和排序。导入接口返回 `imported_card_ids`，导入完成后弹**常驻 MaterialBanner**（文案写明"撤销将删除这批卡片且不可恢复"）承载撤销入口，点击撤销先弹确认对话框再调批量删除，成功后反馈删除数量；卡片列表支持 `new` 筛选（待学新卡 + 学新阶段重学卡，最新在前）、正反面即时搜索（300ms 防抖、搜索时分页拉取完整结果）和多选批量删除（`POST /api/cards/batch-delete`）。
- **全局滚动行为**：`shared/widgets/karis_scroll_behavior.dart` 作为 `MaterialApp.router` 的 `scrollBehavior` 全局生效——桌面/Web 纵向滚动常驻可拖拽滚动条（`scrollbarTheme` 配 `minThumbLength: 48` 兜底，防卡片过多时滚动块过小），触屏保持默认 overlay，横向滚动区域不显示。
- **评分流程**：`review/providers/review_provider.dart` 维护 `ReviewSessionState`（卡片队列、当前索引、是否翻面、cursor、hasMore、待同步数）。在线通过复习会话 cursor 分页；离线回退到 Drift 本地队列；评分先写本地并自动同步。
- **离线数据层**：`frontend/lib/offline/` 使用 Drift/SQLite 缓存卡组、卡片、复习日志与同步元数据；`SyncService` 通过 `/api/sync/bootstrap` 全量或 `event_cursor` 增量同步，提交 `/api/review/sync`，冲突默认按服务器刷新。`sync_events` 由数据库触发器写入，客户端保存事件游标并支持删除同步。**纯计算已下沉**（2026-08-08 架构评审 F5）：统计口径/阶段分布/日志去重在 `offline/offline_stats.dart`（纯函数，口径同后端 ReviewLogQueryPredicates，`offline_stats_test.dart` 直接断言），卡片映射在 `offline/offline_mappers.dart`（LocalCard→FlashCard/ReviewCard 与会话 FlashCard→ReviewCard 单一实现），日期格式化统一 `shared/utils/date_utils.dart` 的 `AppDateUtils.formatDate`（原 4 份副本）；`OfflineRepository` 回归数据访问（1078 → 962 行）。
- **数据变更自动重载**（2026-08-08 架构评审 F4 收敛）：Deck/Stats/Card 三个 notifier 的 `reloadAfterDataChange` 统一委托 `shared/providers/data_refresh_provider.dart` 的 `reloadDataAfterChange`（离线已登录 → 本地重算；无离线或未登录 → 在线重载），provider 定义处监听统一 `listenDataVersion(ref, ...)`——原各自实现 + `ref.listen(dataVersionProvider)` 样板删除。注意：`SyncService` 的 cooldown/inflight 与 `StatsNotifier` 的 TTL/inFlight 是不同层级的状态（服务级并发去重 vs 页面级缓存新鲜度），**不合并**（F4 防过度抽象的边界）。
- **双通道加载骨架**（2026-08-08 架构评审 C1）：Card/Deck/Stats 的「在线/离线双路径加载骨架」收敛为 `shared/providers/dual_channel_loader.dart` 的 `DualChannelLoader`（调用方只提供在线/本地 fetch 与状态回调；Card 的 requestVersion 防抖经 `isStale` 保留、Stats 的 TTL/inFlight 刻意不并入）。
- **评分语义单一源**（2026-08-08 架构评审 E2/D1）：评分值 `shared/scheduling/rating.dart` 的 `Rating` 常量（'FORGET'/'VAGUE'/'FAMILIAR'，代码内一律引用，DB/API 线格式不变）；复习页评分文案/键盘映射/间隔标签收敛为 `review/models/rating_labels.dart` 纯函数（`ratingDisplayLabel`/`ratingOf`/`ratingNextLabel`，`rating_labels_test.dart` 断言）。
- **跨设备评分锁**：`cards.review_version` 是 JPA 乐观锁版本；队列响应携带该值，评分/同步必须校验，旧设备提交会收到冲突。
- **TTS 朗读**：`frontend/lib/tts/` 纯客户端系统 TTS，不碰后端。`TtsEngine` 抽象接口 + 双实现：`SystemTtsEngine`（flutter_tts 4.x，Android/iOS/Windows；`FLUTTER_TEST` 环境下全部短路为 no-op——flutter_tts 的 MethodChannel 在测试 fake async 里挂起而非抛 MissingPluginException）、`LinuxTtsEngine`（spd-say 子进程，**flutter_tts 官方不支持 Linux**，需系统安装 `speech-dispatcher` + `espeak-ng`，未安装时 `isAvailable` 返回 false 按钮隐藏）。`tts_text_extractor.dart` 是纯函数：Delta/Markdown → 朗读文本（正则剥离代码围栏、`$..$`/`$$..$$` 公式，embed 跳过），`splitForSpeech` 按句切分 + CJK 占比判 `zh-CN`/`en-US` 逐段换语言。`ttsProvider` 独立状态（是否在播/读哪面），偏好（开关/语速）存 SharedPreferences 不进后端；换卡/翻面/评分/离页都调 `stop()` 防叠音，复习页 `dispose()` 阶段 ref 不可用需在 `initState` 缓存 notifier 实例。复习页正反面 header 有 `TtsButton`，键盘 `V` 朗读当前面；设置页「朗读」块管开关与语速。Android 的 `<queries>` 已声明 `TTS_SERVICE`（Android 11+ 需要）。
- **音标显示**：`tts/phonetic_dict.dart` 内置美式 IPA 词库（`assets/ipa/en_US_ipa.txt`，open-dict-data/ipa-dict CC0 许可，约 12.5 万词 3.1MB），纯客户端离线查询。只对**纯英文单词/短语**（无中文/数字/标点，允许 `'`/`-`/空格，≤40 字符）显示：`isEnglishPhrase` 判定 → `phoneticFor` 查询（词库惰性加载 + LRU 缓存 256；多音标取第一个；多词逐词拼接；连字符词按 `-` 拆段回退；查不到返回 null）。`widgets/phonetic_line.dart` 渲染到复习页正反面内容下方，非英文/未收录静默不显示。测试注意：`rootBundle.loadString` 是真实 IO，testWidgets 的 fake async 下会挂起，须用 `tester.runAsync` 或构造注入 `seedWords` 词库。

## 测试

- 后端：`mvn test` 会运行纯算法/工具测试（含 `QueueInterleaverTest` 插位规则、`SchedulingEngineTest`）、Service/Controller 部件测试，以及真实 PostgreSQL + HTTP 的系统测试，包含日志、会话分页、同步失效和数据量冒烟；系统测试只创建/清理 `system-test-*@example.com` 测试用户，不清理其他用户数据。
- 前端：`flutter test` 覆盖模型、Repository、Provider、离线调度/Drift、ApiClient、同步服务、操作日志和主要页面 Widget；`queue_composer_test.dart` 直接断言插位规则（不依赖 Drift）；`offline_stats_test.dart` 直接断言统计口径/分布/日志去重（不依赖 Drift）；`offline_repository_test.dart` 含卡列表筛选口径断言（学新重学卡归学新、复习重学卡归复习）；`flutter analyze` 需保持无警告；`flutter test --coverage` 和 release Web 构建用于 CI 验证。
- 数据库迁移已到 V15（V1 用户表 → V15 `learning_origin`，含 V9 同步事件、V10 搜索索引、V11 `user_logs`、V12 验证码表、V13 性能优化、V14 触发器修复），清单与字段见 `docs/design/database.md`；新增表结构必须继续追加迁移。
- 测试层级、运行命令和数据隔离说明见 `docs/design/testing.md`。

## 文档

`docs/README.md` 是文档索引：领域词汇（`docs/CONTEXT.md`，架构评审/设计共用术语）、需求（`docs/requirements/`）、架构/数据库/API 设计（`docs/design/`）。需求文档里有 28 条用户需求，改功能前先对照。API 细节以 `docs/design/api.md` 为准（含所有接口的请求/响应示例）。

代码语义变更（字段、算法、接口、表结构等）时，须同步更新对应文档（本文件、docs/ 下相关文档、迁移脚本）。
