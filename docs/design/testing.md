# 测试说明 — Karis Review

## 测试层级

### 后端部件测试

- 纯算法与工具：`SchedulingEngineTest`、`CardImportParserTest`、`DateUtilsTest`、`JwtProviderTest`。
- Service 部件测试：`AuthServiceTest`、`DeckServiceTest`、`CardServiceTest`、`CardImportServiceTest`、`ReviewServiceTest`、`StatsServiceTest`、`SettingsServiceTest`、`BackupServiceTest`。
- Controller 切片测试：全部 Controller 使用 `@WebMvcTest` + MockMvc，覆盖 HTTP 映射、参数校验、统一响应和业务异常。
- 安全配置测试：`SecurityConfigTest` 覆盖放行路径、未认证访问和无效 Token。

### 后端系统测试

系统测试位于 `src/test/java/.../system/`，启动完整 Spring Boot 随机端口和真实 PostgreSQL，通过 `TestRestTemplate` 走真实 HTTP 全流程：

- `AuthSettingsSystemTest`：注册、登录、设置刷新时间、登出与错误密码。
- `DeckCardSystemTest`：牌组/卡片 CRUD、级联删除、用户隔离和 due 筛选。
- `ReviewStatsSystemTest`：新卡队列、FAMILIAR/FORGET/VAGUE 排期、概览/牌组/趋势统计。
- `ImportBackupSystemTest`：JSON 预览、批量导入、备份导出与覆盖恢复、无效导入整体拒绝。
- `SecuritySystemTest`：401、放行路径和跨用户 404。

系统测试只会创建和清理 `system-test-*@example.com` 前缀测试用户及其级联数据，不会清空其他用户数据。

### 前端部件测试

- 模型测试：`models_test.dart` 覆盖牌组、卡片、复习结果、统计、导入预览等 JSON 解析。
- Repository 测试：`repositories_test.dart` 用 Fake ApiClient 验证请求路径、参数、请求体和响应解析。
- Provider 测试：`providers_test.dart` 覆盖 Auth、Deck、Card、Review、Stats、Settings 的状态转换与错误路径。
- Widget 测试：`widgets_test.dart` 覆盖登录/注册、首页、牌组、卡片、开始流程、复习翻面与评分、导入预览、统计、设置和共享组件。

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
