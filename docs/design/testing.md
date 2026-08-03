# 测试说明 — Karis Review

## 测试层级

### 后端部件测试

- 纯算法与工具：`SchedulingEngineTest`、`CardImportParserTest`、`DateUtilsTest`、`JwtProviderTest`、`InviteCodeConfigTest`。
- Service 部件测试：`AuthServiceTest` 覆盖邀请码禁用/启用、缺失/错误/正确邀请码与注册配置；`DeckServiceTest`、`CardServiceTest`、`CardImportServiceTest`、`ReviewServiceTest`、`StatsServiceTest`、`SettingsServiceTest`、`BackupServiceTest`。
- Controller 切片测试：全部 Controller 使用 `@WebMvcTest` + MockMvc，覆盖 HTTP 映射、参数校验、统一响应和业务异常。
- 安全配置测试：`SecurityConfigTest` 覆盖放行路径、未认证访问、无效 Token 和 `/api/auth/config` 公开访问。

### 后端系统测试

系统测试位于 `src/test/java/.../system/`，启动完整 Spring Boot 随机端口和真实 PostgreSQL，通过 `TestRestTemplate` 走真实 HTTP 全流程：

- `AuthSettingsSystemTest`：注册、登录、设置刷新时间、登出与错误密码。
- `AuthInviteSystemTest`：启用邀请码时公开配置返回 true，缺失/错误邀请码被拒绝，正确邀请码可注册。
- `DeckCardSystemTest`：卡组/卡片 CRUD、级联删除、用户隔离和 due 筛选。
- `ReviewStatsSystemTest`：新卡队列、FAMILIAR/FORGET/VAGUE 排期、概览/卡组/趋势统计。
- `ImportBackupSystemTest`：JSON 预览、批量导入、备份导出与覆盖恢复、无效导入整体拒绝。
- `SecuritySystemTest`：401、放行路径和跨用户 404。
- `SyncSystemTest`：增量游标、变更实体、删除 ID 和删除事件同步。
- `HttpTransportSystemTest`：gzip 压缩、Protobuf 内容协商、ETag/304。

系统测试只会创建和清理 `system-test-*@example.com` 前缀测试用户及其级联数据，不会清空其他用户数据。

### 前端部件测试

- 模型测试：`models_test.dart` 覆盖卡组、卡片、复习结果、统计、导入预览等 JSON 解析。
- Repository 测试：`repositories_test.dart` 用 Fake ApiClient 验证 JSON/Protobuf 请求路径、参数、请求体和响应解析，包含注册配置与邀请码字段。
- 离线同步测试：`offline_repository_test.dart` 覆盖全量 Bootstrap、增量 upsert/删除、事件游标、单飞行刷新和保留待同步日志。
- Provider 测试：`providers_test.dart` 覆盖 Auth、Deck、Card、Review、Stats、Settings 的状态转换与错误路径。
- 自动刷新测试：`auto_refresh_test.dart` 覆盖每日刷新点延迟、`DataRefreshController` 本地/服务端刷新与冷却、统计/卡组/卡片 Provider 版本重算，以及路由变化触发刷新。
- Widget 测试：`widgets_test.dart` 覆盖登录/注册（含邀请码显示/隐藏）、首页、卡组、卡片列表、卡片编辑正反面切换、导入页面、开始流程、复习翻面与评分、统计、设置和共享组件。
## 运行命令

后端完整测试需要 PostgreSQL：

```bash
docker compose up -d postgres
cd backend
mvn test
```

前端测试不需要真实后端：

```bash
cd frontend
flutter pub get
flutter analyze
flutter test
```

CI 中后端测试复用 GitHub Actions 的 PostgreSQL service，前端测试运行 `flutter analyze` 与 `flutter test`。
