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

启动后端前必须先启动 PostgreSQL。测试目前只有 `SchedulingEngineTest`（纯单元测试，无需数据库）和 `KarisreviewApplicationTests`（Spring 上下文加载，需要数据库）。

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

## 架构总览

前后端分离：Flutter 客户端只做 UI 渲染，无本地业务数据存储；服务端无状态，认证靠 JWT（`Authorization: Bearer <token>`，7 天有效）。包名 `top.kariscode.karisreview`，生产环境 `https://review.kariscode.top/api`。详细设计文档见 `docs/`（architecture.md、api.md、database.md）。

### 后端（backend/src/main/java/top/kariscode/karisreview/）

按业务模块分包（`auth`、`deck`、`card`、`review`、`stats`、`backup`、`settings`），每个模块内部单向依赖 `controller → service → repository`。模块间严禁循环依赖：`card → deck`、`review → card/deck`、`stats → review/deck`、`backup` 依赖全部模块。

关键点：

- **用户身份获取**：`JwtAuthenticationFilter`（`config/`）解析 Token 后把 `UUID userId` 放进 `SecurityContextHolder`；Controller 用 `@AuthenticationPrincipal UUID userId` 拿到当前用户。所有业务查询都以 `userId` 过滤，实体用 `UUID` 外键字段（如 `card.getDeckId()`）而非 JPA 关联对象。
- **统一响应**：所有接口返回 `common/dto/ApiResponse`（`code`/`message`/`data`）；业务错误抛 `BusinessException(code, message)`，由 `common/exception/GlobalExceptionHandler` 统一处理。
- **权限边界**：`SecurityConfig` 放行 `/api/auth/register`、`/api/auth/login` 以及 OpenAPI 文档路径（`/v3/api-docs/**`、`/swagger-ui/**`、`/swagger-ui.html`），其余全部要求认证。跨域配置在 `CorsConfig`（全放开）。
- **API 文档**：集成 Springdoc OpenAPI 3，配置了 JWT Bearer 安全方案；登录/注册接口豁免认证要求，生产 profile 关闭文档。
- **"今天"的定义**：不是自然日。`common/util/DateUtils.calculateToday(refreshTime)` 依据用户设置的 `refresh_time`（默认 04:00）计算"今天"范围——当前时间在刷新点之前时算前一天。所有到期判断（due、stats、学习模式插入位置）都基于此。
- **数据库变更**：`ddl-auto=none`，schema 由 Flyway 迁移管理（`src/main/resources/db/migration/V1~V7`）。改表必须新增迁移脚本，不能改已提交的脚本。
- **统计口径**：`review_logs.is_new_card` 标记评分时是否为 Stage 0 且非重学的新卡；今日复习不含新学，今日新学只统计新卡上的 FAMILIAR。
- **卡片快捷导入**：`card/service/CardImportParser` 负责解析 JSON 数组，`CardImportService` 校验牌组归属并批量写入新卡；`CardImportController` 暴露 `/api/decks/{deckId}/cards/import/preview` 与 `/api/decks/{deckId}/cards/import`，不写复习记录和排期状态。

#### 排期算法（核心业务逻辑）

`review/service/SchedulingEngine.java` 是零依赖的纯算法类（便于单测），`ReviewService` 负责编排：

- **Stage 0-8**，间隔为 `{0, 1, 2, 4, 7, 15, 30, 90, 180}` 天。
- **FAMILIAR**：非重学模式升级 1 级；Stage 0 → 1（1 天后）。
- **FORGET**：重置 Stage 0 并进入重学模式（`learning_mode=true`），需连续 5 次 Familiar 才脱离（回 Stage 1）。
- **VAGUE**：降 1 级并进入重学模式，`reentry_stage` 记录目标级别，只需连续 3 次 Familiar 脱离并回到该级别（复习间隔 = 该级间隔 − 上一级间隔）；Stage 1 的 VAGUE 视同 FORGET。
- **重学插入**：重学中的卡片按 `learning_step`（2^n 间距）插入到期队列，`ReviewService.interleaveLearningCards` 实现（第 1 次隔 1 张、第 2 次隔 2 张、第 3 次隔 4 张……）。

`Card` 实体新增了 `learning_step` 字段（V6 迁移），数据库文档中的表结构没有它，改卡字段时注意同步。

#### 备份（backup/）

- `BackupService.exportData`：导出用户全量数据（decks/cards/review_logs）为 JSON，同时存一份 `backup_snapshots` 快照。
- `BackupService.importData`：**先删光该用户现有数据再导入**（不可逆）。导入的卡片获得新 ID，复习日志靠 `card_front`（front+back 组合键，front 可能重复时取首个匹配）重新关联。
- `BackupScheduler`：`@Scheduled(cron = "0 10 4 * * *")` 每天 04:10 为所有用户做应用级备份（`SchedulingConfig` 开启调度）。

### 前端（frontend/lib/）

按业务模块分包，每个模块统一为 `repositories/`（Dio 调用）→ `providers/`（Riverpod StateNotifier，持有不可变 state 类）→ `pages/`（ConsumerWidget/ConsumerStatefulWidget）→ `models/`（序列化类）。

- **API 客户端**：`shared/api/api_client.dart` 的 Dio 单例，拦截器自动附加 Token（SharedPreferences 存储）并在 401 时清除。基础 URL 与端点常量在 `shared/api/api_endpoints.dart`。
- **路由/鉴权**：`app/router.dart` 的 GoRouter 监听 `authProvider` 做重定向（未登录 → `/login`，已登录访问登录页 → `/decks`）。`/review/due` 与 `/review/new` 共用 `ReviewPage`，用 `filter` 参数区分学习/复习模式，牌组筛选走 `deck_id` query 参数。
- **富文本**：卡片正反面存 Quill Delta JSON 字符串（`flutter_quill` 编辑器，LaTeX 和代码块是自定义 custom block embed）。`shared/widgets/rich_card_content.dart` 渲染时自动识别——内容以 `[` 开头且可解析为 JSON 列表则按 Delta 渲染，否则按轻量 Markdown 解析（`**粗体**`、`*斜体*`、`` `行内代码` ``、`# 标题`、`- 列表`、`$$...$$` 行间公式、`$...$` 行内公式、` ``` 代码块 ````），并对 Delta/普通文本两种格式都做了容错处理。
- **卡片编辑**：`card/pages/card_editor_page.dart` 为独立页面，正面/反面通过分段切换编辑，不把两面同时堆在一个界面里。
- **卡片快捷导入**：`card/pages/card_import_page.dart` 为独立页面，支持粘贴 JSON 或选择 `.json` 文件；解析和最终导入都走后端，预览阶段可编辑/删除行，不支持新增和排序。
- **评分流程**：`review/providers/review_provider.dart` 维护 `ReviewSessionState`（卡片队列、当前索引、是否翻面），评分后推进索引。
- 另有 `shared/widgets/loading_widget.dart`、`error_widget.dart` 等通用组件。

## 测试

- 后端：`mvn test` 会运行纯算法/工具测试、Service 与 Controller 部件测试，以及真实 PostgreSQL + HTTP 的系统测试；系统测试只创建/清理 `system-test-*@example.com` 测试用户，不清理其他用户数据。
- 前端：`flutter test` 覆盖模型、Repository、Provider 和主要页面 Widget；`flutter analyze` 需保持无警告。
- 测试层级、运行命令和数据隔离说明见 `docs/design/testing.md`。

## 文档

`docs/README.md` 是文档索引：需求（`docs/requirements/`）、架构/数据库/API 设计（`docs/design/`）。需求文档里有 27 条用户需求，改功能前先对照。API 细节以 `docs/design/api.md` 为准（含所有接口的请求/响应示例）。

代码语义变更（字段、算法、接口、表结构等）时，须同步更新对应文档（本文件、docs/ 下相关文档、迁移脚本）。
