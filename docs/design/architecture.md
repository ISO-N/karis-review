# 体系结构设计 — Karis Review

## 1. 系统架构概览

```
┌──────────────────────────────────────────────────────────────────┐
│                        Flutter 客户端                             │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  UI Layer                                                  │  │
│  │  (Widgets, Pages, GoRouter, Theme)                        │  │
│  ├────────────────────────────────────────────────────────────┤  │
│  │  State Management (Riverpod)                               │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐     │  │
│  │  │ Auth     │ │ Deck     │ │ Card     │ │ Review   │     │  │
│  │  │ Provider │ │ Provider │ │ Provider │ │ Provider │     │  │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘     │  │
│  ├────────────────────────────────────────────────────────────┤  │
│  │  Repository Layer (API Client)                             │  │
│  │  (Dio HTTP Client, DTO Serialization)                     │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────┬───────────────────────────────────────┘
                           │ HTTPS / JSON
                           ▼
┌──────────────────────────────────────────────────────────────────┐
│                      Java 后端 (Spring Boot)                      │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  Controller Layer (REST Controllers)                       │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐     │  │
│  │  │ Auth     │ │ Deck     │ │ Card     │ │ Review   │     │  │
│  │  │ Controller│ │ Controller│ │ Controller│ │ Controller│     │  │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘     │  │
│  ├────────────────────────────────────────────────────────────┤  │
│  │  Service Layer (Business Logic)                            │  │
│  │  ┌──────────┐ ┌──────────────────┐ ┌──────────┐          │  │
│  │  │ Auth     │ │ SchedulingEngine │ │ Stats    │          │  │
│  │  │ Service  │ │ (Core Algorithm) │ │ Service  │          │  │
│  │  └──────────┘ └──────────────────┘ └──────────┘          │  │
│  ├────────────────────────────────────────────────────────────┤  │
│  │  Repository Layer (Spring Data JPA)                       │  │
│  │  ┌──────┐ ┌──────┐ ┌──────────┐ ┌──────────┐            │  │
│  │  │ User │ │ Deck │ │ Card     │ │ ReviewLog│            │  │
│  │  │ Repo │ │ Repo │ │ Repo     │ │ Repo     │            │  │
│  │  └──────┘ └──────┘ └──────────┘ └──────────┘            │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────┬───────────────────────────────────────┘
                           │
                           ▼
              ┌──────────────────────┐
              │     PostgreSQL       │
              │   (karis_review)     │
              └──────────────────────┘
```

## 2. 架构风格

- **前后端分离**：Flutter 客户端负责 UI 渲染、交互和离线缓存；服务端保持业务权威，客户端离线写入会在联网后同步
- **RESTful API**：客户端与服务端通过 HTTP 通信，默认 JSON，高流量接口支持 `application/x-protobuf` 内容协商
- **无状态服务端**：认证通过 JWT Token 实现，服务端不维护会话状态
## 3. 包结构

### 3.1 后端（Java）

```
top.kariscode.karisreview
├── KarisReviewApplication.java          # Spring Boot 入口
│
├── config/
│   ├── SecurityConfig.java              # Spring Security 配置
│   ├── CorsConfig.java                  # 跨域配置
│   ├── JacksonConfig.java               # JSON 序列化配置
│   ├── OpenApiConfig.java               # OpenAPI 3 + JWT Bearer 配置
│   ├── InviteCodeConfig.java            # 注册邀请码开关与校验
│   ├── JwtProvider.java                 # JWT 签发/校验
│   ├── JwtAuthenticationFilter.java     # Bearer Token 过滤器
│   └── ProtobufHttpMessageConverter.java
│
├── common/
│   ├── exception/
│   │   ├── GlobalExceptionHandler.java  # 全局异常处理（JSON/Protobuf）
│   │   └── BusinessException.java       # 业务异常
│   ├── dto/
│   │   └── ApiResponse.java             # 统一响应格式
│   ├── etag/
│   │   └── UserEtagService.java         # 用户级 ETag
│   └── util/
│       └── DateUtils.java               # 业务日期工具
│
├── auth/
│   ├── controller/AuthController.java
│   ├── service/AuthService.java
│   ├── service/PasswordResetService.java        # 找回密码/注册验证码编排
│   ├── service/PasswordResetCodeService.java    # 验证码生成/校验/消费
│   ├── service/MailSender.java                  # 邮件抽象接口
│   ├── service/NoopMailSender.java              # 未配 SMTP 时只打日志
│   ├── service/SmtpMailSender.java              # 配 SMTP 后真实发送（支持 SOCKS 代理）
│   ├── entity/User.java
│   ├── entity/PasswordResetCode.java            # 邮箱验证码记录（email_verification_codes 表）
│   ├── repository/UserRepository.java
│   ├── repository/PasswordResetCodeRepository.java
│   └── dto/
│       ├── AuthConfigResponse.java
│       ├── RegisterRequest.java
│       ├── LoginRequest.java
│       ├── LoginResponse.java
│       ├── ChangePasswordRequest.java
│       ├── SendRegisterCodeRequest.java
│       ├── SendResetCodeRequest.java
│       └── ResetPasswordRequest.java
│
├── deck/
│   ├── controller/DeckController.java
│   ├── service/DeckService.java
│   ├── entity/Deck.java
│   ├── repository/DeckRepository.java
│   └── dto/
│       ├── DeckCreateRequest.java
│       ├── DeckUpdateRequest.java
│       └── DeckResponse.java
│
├── card/
│   ├── controller/CardController.java
│   ├── controller/CardImportController.java
│   ├── service/
│   │   ├── CardService.java
│   │   ├── CardImportService.java
│   │   └── CardImportParser.java
│   ├── entity/Card.java
│   ├── repository/CardRepository.java
│   └── dto/
│       ├── CardCreateRequest.java
│       ├── CardUpdateRequest.java
│       ├── CardResponse.java
│       └── CardImport*.java
│
├── review/
│   ├── controller/ReviewController.java
│   ├── service/
│   │   ├── ReviewService.java
│   │   ├── ReviewProtoMapper.java
│   │   └── SchedulingEngine.java       # 排期算法核心
│   ├── entity/
│   │   ├── ReviewLog.java
│   │   ├── ReviewSession.java
│   │   └── ReviewQueueItem.java
│   ├── repository/
│   │   ├── ReviewLogRepository.java
│   │   ├── ReviewSessionRepository.java
│   │   └── ReviewQueueItemRepository.java
│   └── dto/
│       ├── ReviewCardResponse.java
│       ├── RateRequest.java
│       └── ReviewSync*.java
│
├── stats/
│   ├── controller/StatsController.java
│   ├── service/StatsService.java
│   └── dto/
│       ├── OverviewStatsResponse.java
│       ├── DeckStatsResponse.java
│       └── TrendStatsResponse.java
│
├── backup/
│   ├── controller/BackupController.java
│   ├── service/
│   │   ├── BackupService.java
│   │   └── BackupScheduler.java
│   ├── entity/BackupSnapshot.java
│   └── repository/BackupRepository.java
│
├── settings/
│   ├── controller/SettingsController.java
│   ├── service/SettingsService.java
│   └── dto/
│       ├── UserSettingsResponse.java
│       └── UpdateSettingsRequest.java
│
├── sync/
│   ├── controller/SyncController.java
│   ├── service/
│   │   ├── SyncService.java
│   │   └── SyncProtoMapper.java
│   └── repository/SyncEventRepository.java
│
└── log/
    ├── controller/LogController.java
    ├── service/UserLogService.java
    ├── entity/UserLog.java
    ├── repository/UserLogRepository.java
    └── util/LogDesensitizer.java
```

### 3.2 前端（Flutter）

```
lib/
├── main.dart                            # App 入口
│
├── app/
│   ├── app.dart                         # MaterialApp + GoRouter
│   ├── router.dart                      # 路由定义
│   └── theme.dart                       # 主题配置
│
├── shared/
│   ├── api/
│   │   ├── api_client.dart              # Dio HTTP 客户端（Token/ETag/重试/Protobuf）
│   │   └── api_endpoints.dart           # API 端点常量
│   ├── proto/
│   │   ├── karis_review.pb.dart
│   │   └── proto_mappers.dart
│   ├── providers/
│   │   ├── data_refresh_provider.dart
│   │   └── locale_provider.dart
│   ├── navigation/auto_refresh_observer.dart
│   ├── utils/
│   │   ├── app_timezone.dart
│   │   ├── daily_refresh.dart
│   │   └── date_utils.dart
│   └── widgets/
│       ├── adaptive_scaffold.dart
│       ├── stage_ruler.dart
│       ├── metric_tile.dart
│       ├── settings_action_tile.dart
│       ├── section_widgets.dart
│       ├── loading_widget.dart
│       ├── error_widget.dart
│       └── rich_card_content.dart
│
├── offline/
│   ├── database/app_database.dart       # Drift/SQLite
│   ├── local_scheduling_engine.dart
│   ├── offline_repository.dart
│   └── providers.dart
│
├── auth/
│   ├── providers/auth_provider.dart
│   ├── repositories/auth_repository.dart
│   ├── pages/login_page.dart
│   ├── pages/register_page.dart
│   └── models/
│       ├── auth_config.dart
│       ├── login_request.dart
│       ├── login_response.dart
│       └── register_request.dart
│
├── deck/
│   ├── providers/deck_provider.dart
│   ├── repositories/deck_repository.dart
│   ├── pages/deck_list_page.dart
│   ├── widgets/deck_row.dart
│   └── models/deck.dart
│
├── card/
│   ├── providers/card_provider.dart
│   ├── repositories/card_repository.dart
│   ├── pages/
│   │   ├── card_list_page.dart
│   │   ├── card_editor_page.dart
│   │   └── card_import_page.dart
│   └── models/
│       ├── card.dart
│       └── card_import.dart
│
├── review/
│   ├── providers/review_provider.dart
│   ├── repositories/review_repository.dart
│   ├── pages/
│   │   ├── review_page.dart
│   │   └── start_flow_page.dart
│   ├── widgets/review_flip_card.dart
│   └── models/review_card.dart
│
├── sync/
│   ├── repositories/sync_repository.dart
│   ├── sync_service.dart
│   └── providers.dart
│
├── log/
│   ├── repositories/logs_repository.dart
│   ├── providers/logs_provider.dart
│   └── pages/logs_page.dart
│
├── home/pages/home_page.dart
│
├── stats/
│   ├── providers/stats_provider.dart
│   ├── providers/deck_stats_provider.dart
│   ├── repositories/stats_repository.dart
│   ├── pages/stats_page.dart
│   └── models/stats.dart
│
└── settings/
    ├── providers/settings_provider.dart
    ├── repositories/settings_repository.dart
    └── pages/settings_page.dart
```

## 4. 关键技术选型

| 层级 | 技术 | 版本 | 说明 |
|------|------|------|------|
| 前端框架 | Flutter | 3.x | 跨平台 UI |
| 状态管理 | Riverpod | 2.x | 编译安全，依赖注入 |
| 路由 | GoRouter | 14.x | 官方声明式路由 |
| HTTP 客户端 | Dio | 5.x | 拦截器、重试、超时 |
| 富文本编辑 | flutter_quill | 10.x | 富文本编辑器 |
| LaTeX 渲染 | flutter_math_fork | 0.7.x | 数学公式渲染 |
| 代码高亮 | flutter_highlight | 0.7.x | 语法高亮 |
| 后端框架 | Spring Boot | 3.x | Java 生态最成熟 |
| Java 版本 | Java | 21 (LTS) | 当前最新 LTS |
| ORM | Spring Data JPA + Hibernate | — | 与 Spring Boot 深度集成 |
| 数据库迁移 | Flyway | 10.x | Schema 版本管理 |
| 认证 | Spring Security + JWT | 6.x | 安全框架 |
| API 文档 | Springdoc OpenAPI | 2.8.x | OpenAPI 3 + Swagger UI |
| 数据库 | PostgreSQL | 16.x | 关系型数据库 |
| 数据库名 | karis_review | — | — |

## 5. API 文档

- 使用 `springdoc-openapi-starter-webmvc-ui` 自动生成 OpenAPI 3 文档。
- 默认地址：`/v3/api-docs`、`/swagger-ui.html`。
- 受保护 Controller 用 `@SecurityRequirement` 声明 `bearerAuth` JWT 安全方案；登录/注册/注册配置/发验证码/重置密码接口不要求。
- 注册公开配置接口 `GET /api/auth/config` 只返回 `invite_code_required`，不暴露邀请码本身。
- `SecurityConfig` 放行 `/api/auth/config`、`/api/auth/register`、`/api/auth/register-code`、`/api/auth/login`、`/api/auth/password/reset-code`、`/api/auth/password/reset`、`/v3/api-docs/**`、`/swagger-ui/**`、`/swagger-ui.html`。
- 生产环境使用 `prod` profile 时关闭文档。
- 邮件发送通过 `MailSender` 抽象：未配置 `mail.smtp.host` 时用 `NoopMailSender`（验证码仅打日志，便于本地开发）；配置后自动切换 `SmtpMailSender`。SMTP 支持 `mail.smtp.socks.host`/`mail.smtp.socks.port` 走本地 SOCKS5 代理（Resend 等境外服务在国内部署时使用）。

## 6. 模块间依赖关系
```
auth ──────► common
deck ──────► auth, common
card ──────► deck, auth, common
review ────► card, deck, auth, common  (依赖 SchedulingEngine)
stats ─────► review, deck, auth, common
backup ────► deck, card, review, auth, common  (全量导出)
settings ──► auth, common
sync ──────► auth, deck, card, review, common
log ───────► common
- 每个模块内部按 `controller → service → repository` 单向依赖
- 模块间**严禁循环依赖**（review 可调用 card 的 Service，但 card 不可反向调用 review）
- `SchedulingEngine` 作为独立的核心算法类，零外部依赖，便于单元测试

## 7. 离线与同步架构

前端新增 Drift/SQLite 本地数据层：缓存卡组、卡片、复习日志和同步元数据；在线复习使用服务端 `review_sessions` 快照 + cursor 分页，离线回退到本地队列。

后端新增 `sync` 模块提供 `/api/sync/bootstrap`；`review` 模块提供 `/api/review/sessions` 和 `/api/review/sync`。`sync` 依赖 `auth/deck/card/review`，不引入循环依赖。

`sync_events` 表由数据库触发器记录卡组、卡片、复习日志和用户设置的创建/更新/删除事件。客户端保存单调 `event_cursor`，增量请求只拉取变更实体、新增日志和删除 ID；游标不可用时通过 `reset_required` 回退全量同步。

## 7.1 传输优化

- 服务端开启 gzip 压缩，稳定列表/统计接口返回私有 ETag 并支持 304。
- 同步 Bootstrap、复习会话/分页、复习队列、评分同步支持同 URL Protobuf 内容协商；默认 JSON，客户端生产请求优先使用 Protobuf。
- 前端 `SyncService` 对刷新做单飞行与冷却，评分同步做防抖批量提交，避免重复下载和重复请求。
- `review_logs` 同步回传时携带 `client_request_id`，Drift 用它替换本地待同步镜像，统计层对旧重复数据去重，避免同一评分被计两次。

## 7.2 自动刷新与关键时机同步

前端通过 `dataVersionProvider` 与 `DataRefreshController` 统一触发数据重算：本地写操作只递增版本号，相关 Provider 从 Drift 重新计算；服务端刷新先调用 `SyncService.refresh()`，成功后再递增版本号。

自动刷新覆盖以下关键时机：

- 复习评分、离线评分同步完成、冲突解决或卡片删除后立即重算。
- 卡片/卡组增删改与导入完成后刷新当前页面相关 Provider。
- 修改每日刷新时间后立即重算“今天”并重新排程。
- 进入或返回首页、卡组、卡片列表、统计、开始页、设置页时执行静默增量同步。
- 应用回到前台时执行静默增量同步。
- 应用保持前台跨过每日刷新点后自动重算。

自动刷新不打断当前页面，失败时静默保留本地数据；用户仍可下拉刷新显式重试。当前不引入前台周期轮询或服务端推送，跨设备实时同步可作为后续增强。

“今天”和每日刷新点按全局业务时区计算：后端通过 `app.timezone`（默认 `Asia/Shanghai`）判断，前端 `LocalSchedulingEngine` 与每日刷新调度也按 UTC+8 换算，不依赖设备时区。同步接口的 `server_time` 保持 UTC。

## 8. 跨设备评分锁

`cards.review_version` 是 JPA `@Version` 乐观锁字段。评分和同步接口在事务内用 `PESSIMISTIC_WRITE` 锁住卡片并校验版本，旧设备提交会得到冲突，不会重复排期。