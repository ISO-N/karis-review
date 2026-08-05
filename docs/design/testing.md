# 测试说明 — Karis Review

## 测试层级

### 后端部件测试

- 纯算法与工具：`SchedulingEngineTest`、`CardImportParserTest`、`DateUtilsTest`、`JwtProviderTest`、`InviteCodeConfigTest`、`LogDesensitizerTest`。
- Service 部件测试：`AuthServiceTest`、`PasswordResetServiceTest`、`PasswordResetCodeServiceTest`、`DeckServiceTest`、`CardServiceTest`、`CardImportServiceTest`、`ReviewServiceTest`、`ReviewSessionServiceTest`、`SyncServiceTest`、`StatsServiceTest`、`SettingsServiceTest`、`BackupServiceTest`、`BackupSchedulerTest`、`UserLogServiceTest`、`UserEtagServiceTest`。
- Mapper 与异常：`SyncProtoMapperTest`、`ReviewProtoMapperTest`、`GlobalExceptionHandlerTest`。
- Controller 切片测试：`@WebMvcTest` + MockMvc 覆盖 HTTP 映射、参数校验、统一响应、Protobuf 响应和业务异常。
- 安全配置测试：`SecurityConfigTest` 覆盖放行路径、未认证访问、无效 Token 和 `/api/auth/config` 公开访问。
### 后端系统测试

系统测试位于 `src/test/java/.../system/`，启动完整 Spring Boot 随机端口和真实 PostgreSQL，通过 `TestRestTemplate` 走真实 HTTP 全流程：

- `AuthSettingsSystemTest`：注册（含邮箱验证码）、登录、设置刷新时间、修改密码、找回密码、登出与错误密码。
- `AuthInviteSystemTest`：启用邀请码时公开配置返回 true，缺失/错误邀请码被拒绝，正确邀请码可注册。
- `DeckCardSystemTest`：卡组/卡片 CRUD、级联删除、用户隔离和 due 筛选。
- `ReviewStatsSystemTest`：新卡队列、FAMILIAR/FORGET/VAGUE 排期、概览/卡组/趋势统计。
- `ImportBackupSystemTest`：JSON 预览、批量导入、备份导出与覆盖恢复、无效导入整体拒绝。
- `SecuritySystemTest`：401、放行路径和跨用户 404。
- `SyncSystemTest`：增量游标、变更实体、删除 ID、用户设置变更、删除卡片和游标失效重置。
- `ReviewSessionSystemTest`：会话创建、cursor 分页、删除会话、过期 410 和跨用户 404。
- `LogSystemTest`：注册日志可见、level/category 过滤和分页。
- `PerformanceSmokeSystemTest`：1001 张卡片下的列表分页、搜索、统计和复习队列冒烟。
- `HttpTransportSystemTest`：gzip 压缩、Protobuf 内容协商、ETag/304。
系统测试只会创建和清理 `system-test-*@example.com` 前缀测试用户及其级联数据，不会清空其他用户数据。

### 前端部件测试

- 模型测试：`models_test.dart` 覆盖卡组、卡片、复习结果、统计、导入预览等 JSON 解析。
- API 客户端测试：`api_client_test.dart` 覆盖 Bearer Token、401 回调、ETag/304、瞬态错误重试和 Protobuf 错误。
- Repository 测试：`repositories_test.dart`、`logs_repository_test.dart` 用 Fake ApiClient 验证请求路径、参数、请求体和响应解析。
- 离线同步测试：`offline_repository_test.dart` 覆盖全量 Bootstrap、增量 upsert/删除、事件游标、单飞行刷新、保留待同步日志和本地统计口径；`sync_service_test.dart` 覆盖同步结果状态处理与全量回退。
- Provider 测试：`providers_test.dart`、`logs_provider_test.dart` 覆盖 Auth、Deck、Card、Review、Stats、Settings、Logs 的状态转换、分页和错误路径。
- 自动刷新测试：`auto_refresh_test.dart` 覆盖每日刷新点延迟、`DataRefreshController` 本地/服务端刷新与冷却、统计/卡组/卡片 Provider 版本重算，以及路由变化触发刷新。
- Widget 测试：`widgets_test.dart`、`logs_page_test.dart`、`router_test.dart` 覆盖登录/注册、首页、卡组、卡片列表、编辑、导入、复习、统计、设置、操作日志、路由鉴权和共享组件。
## 运行命令

后端完整测试需要 PostgreSQL，生成 JaCoCo 报告时使用 `verify`：

```bash
docker compose up -d postgres
cd backend
./mvnw test
./mvnw verify   # 额外生成 target/site/jacoco/index.html
```

前端测试不需要真实后端：

```bash
cd frontend
flutter pub get
flutter analyze
flutter test
flutter test --coverage
flutter build web --release
```
CI 中后端测试复用 GitHub Actions 的 PostgreSQL service；前端测试运行 `flutter analyze`、`flutter test --coverage` 与 release Web 构建。

## 数据库性能验证

性能优化（V13/V14 迁移 + 应用层批量改造，见 architecture.md §9 与 database.md §4）落地后，用 EXPLAIN 验证查询计划，重点确认**从 Seq Scan / Sort 变为 Index Scan**。本地开发库数据量小时优化器会合理选择 Seq Scan，需在预发布环境用真实数据量验证。

```sql
-- 1) 复习队列：期望 Index Scan using idx_cards_next_review，无 Sort 节点
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM cards
WHERE user_id = 'xxx' AND next_review_date IS NOT NULL
  AND next_review_date <= '2026-08-05' AND learning_mode = false
ORDER BY next_review_date ASC LIMIT 50;

-- 2) 新卡队列：期望 Index Scan using idx_cards_user_stage_learning
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM cards
WHERE user_id = 'xxx' AND stage = 0 AND learning_mode = false
ORDER BY created_at ASC LIMIT 10;

-- 3) 统计聚合（StatsService.getOverview）：期望 Index Only Scan using idx_cards_user_stage_learning
EXPLAIN (ANALYZE, BUFFERS)
SELECT stage, COUNT(*) AS total,
       COUNT(*) FILTER (WHERE stage < 5) AS learning_cards,
       COUNT(*) FILTER (WHERE NOT learning_mode AND stage >= 5) AS mastered,
       COUNT(*) FILTER (WHERE stage = 0 AND NOT learning_mode) AS new_cards,
       COUNT(*) FILTER (WHERE next_review_date IS NOT NULL
                         AND next_review_date <= '2026-08-05') AS due
FROM cards WHERE user_id = 'xxx' GROUP BY stage;
```

压测建议：构造 5k / 50k 卡片用户数据，对 `/api/review/sync`（50 条评分）、`/api/decks/{id}/cards`（分页+搜索）、`/api/stats/overview` 做改动前后对比。
