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
├── tts/
│   ├── tts_engine.dart                  # TTS 引擎抽象接口 + 平台工厂
│   ├── system_tts_engine.dart           # flutter_tts 实现（Android/iOS/Windows）
│   ├── linux_tts_engine.dart            # spd-say 子进程实现（Linux）
│   ├── tts_text_extractor.dart          # Delta/Markdown → 朗读文本 + 语言分段
│   ├── tts_provider.dart                # 朗读状态与本地偏好（开关/语速）
│   ├── phonetic_dict.dart               # 美式 IPA 词库加载/判定/查询（离线）
│   └── widgets/
│       ├── tts_button.dart              # 复习页正反面朗读按钮
│       └── phonetic_line.dart           # 单词音标行（纯英文内容显示）
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
| 系统 TTS | flutter_tts | 4.x | Android/iOS/Windows 朗读（Linux 用 spd-say） |
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

### 5.1 TTS 朗读（前端 `tts/` 模块）

纯客户端系统 TTS，不依赖后端与网络。分层与关键设计：

- **引擎抽象**：`TtsEngine` 接口（`isAvailable/setSpeechRate/speakSegments/stop/dispose`），为云端神经网络 TTS 预留扩展位。
- **双实现**：
  - `SystemTtsEngine`（flutter_tts 4.x）：Android / iOS / Windows。iOS 设 `ambient + mixWithOthers` 音频会话，朗读时音乐可继续。
  - `LinuxTtsEngine`（spd-say 子进程）：flutter_tts **官方不支持 Linux**，Linux 端调用 `speech-dispatcher` 命令行客户端，每段一个 `spd-say -l <lang> -r <rate> -w <text>` 进程，`stop()` kill 当前进程 + 代数递增打断循环。
  - 工厂 `createTtsEngine()` 按 `Platform.isLinux` 选择。测试环境（`FLUTTER_TEST`）下 SystemTtsEngine 全部短路为 no-op——flutter_tts 的 MethodChannel 在 fake async 下挂起而非抛 MissingPluginException，短路避免测试卡死。
- **文本提取**（`tts_text_extractor.dart`，纯函数可单测）：卡片内容（Delta JSON / Markdown）→ 朗读纯文本。Delta 只取 String insert，embed（LaTeX/代码块）跳过；Markdown 用正则剥离代码围栏、`$..$`/`$$..$$` 公式、行内代码标记、标题/列表/粗斜体。
- **中英混读**：`splitForSpeech` 按句末标点切分，CJK ≥ 2 字符判 `zh-CN` 否则 `en-US`，相邻同语言段合并；引擎逐段 `setLanguage` 后朗读，实现中英混合卡片的正确发音。
- **状态与生命周期**：`ttsProvider` 独立于 `reviewProvider`，管三件事——是否在播、读哪面、本地偏好（开关/语速，存 SharedPreferences，不进后端不参与同步）。换卡、翻面、评分、离开复习页均调用 `stop()` 防叠音。复习页 `dispose()` 阶段 ref 不可用，故在 `initState` 缓存 notifier 实例再调 stop。
- **UI**：复习页正反面 header 各有 `TtsButton`（引擎不可用或关闭时不占位），键盘 `V` 朗读当前面；设置页「朗读」块含开关与语速滑块（0.5–1.5x）。
- **音标显示**（`phonetic_dict.dart` + `widgets/phonetic_line.dart`）：卡片某面为**纯英文单词/短语**时（无中文/数字/标点，允许撇号、连字符、空格，≤40 字符），内容下方显示美式 IPA 音标。词库 `assets/ipa/en_US_ipa.txt` 源自 `open-dict-data/ipa-dict`（CC0 许可），约 12.5 万词、3.1MB（已过滤缩写词、去除音标包裹斜杠）；首次查询惰性加载进内存，结果 LRU 缓存（容量 256）。规则：一词多音标（record 名词/动词重音不同）取第一个主要发音；多词按空格逐词拼接；连字符合成词整体查不到按 `-` 拆段回退；未收录或非纯英文一律返回 null，UI 静默不显示。纯客户端离线查询，不碰后端、不动表结构。

平台配置要求：

- Android：minSdk ≥ 21（项目 `flutter.minSdkVersion` 默认 24 满足）；`AndroidManifest.xml` 的 `<queries>` 已声明 `android.intent.action.TTS_SERVICE`（Android 11+ 发现引擎需要）。
- Windows：flutter_tts 走 WinRT SpeechSynthesis，需 Windows 10 1809+；非中文系统可能缺中文 voice，`isAvailable` 只检测语言列表非空，缺 voice 时按钮隐藏。**构建前置**：flutter_tts 的 Windows 插件用 NuGet 拉取 `Microsoft.Windows.CppWinRT` 依赖，构建机需要 `nuget.exe` 在 PATH（`find_program` 找不到会直接 CMake fatal error）。本机已放一份在 `~/.workbuddy/binaries/nuget/nuget.exe`，构建前 `export PATH="$HOME/.workbuddy/binaries/nuget:$PATH"` 即可。
- Linux：运行时依赖 `speech-dispatcher` + `espeak-ng`（`apt install speech-dispatcher espeak-ng`）；未安装时 `isAvailable` 返回 false，UI 提示安装。Linux 实现是纯 Dart 子进程，无额外构建依赖。

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

`sync_events` 保留 60 天（`SyncService.cleanupOldSyncEvents()` 每日清理，见 database.md §4.2）。清理后旧客户端游标可能指向已删除事件，`deltaBootstrap` 通过 `SyncEventRepository.minSeq()`/`latestSeq()` 判断：游标早于最早保留事件或事件被整体清空时，自动降级为全量同步（等价于 `reset_required`），保证增量一致性不因清理而破坏。

## 7.1 传输优化

- 服务端开启 gzip 压缩，稳定列表/统计接口返回私有 ETag 并支持 304。
- 同步 Bootstrap、复习会话/分页、复习队列、评分同步支持同 URL Protobuf 内容协商；默认 JSON，客户端生产请求优先使用 Protobuf。
- 前端 `SyncService` 对刷新做单飞行与冷却，评分同步做防抖批量提交，避免重复下载和重复请求。
- `review_logs` 同步回传时携带 `client_request_id`，Drift 用它替换本地待同步镜像，统计层对旧重复数据去重，避免同一评分被计两次。

## 7.1.1 队列归属与统计口径（learning_origin）

重学卡（`learning_mode=true`）按进入重学时的阶段决定归属，`cards.learning_origin`（V15 迁移）记录来源：

- `NEW`：学新阶段（新卡）忘记进入重学 → 归**学新队列**（新卡 + `NEW` 重学卡按 2^n 间距插入）。
- `REVIEW`：复习阶段（到期卡）忘记/模糊进入重学 → 归**复习队列**（到期卡 + `REVIEW` 重学卡按 2^n 间距插入）。
- null：非重学或历史数据（旧数据按 `REVIEW` 处理，保持原行为）。

服务端 `ReviewService.buildNewQueue/buildDueQueue` 与前端离线 `OfflineRepository.getNewQueue/getDueQueue` 按同一来源规则构建队列，因此学新页忘记/模糊的卡退出重进后仍能在学新队列遇到；重学中再忘记/模糊保持原来源，脱离重学（连续 Familiar 达标）清除来源。

统计口径随之调整（前后端一致）：

- `reviewed_today`（已复习）：今日 `is_new_card=false` 且 `learning_origin <> 'NEW'` 的评分——到期卡复习 + 复习阶段重学计入；学新阶段的重学评分不计入。
- `due_today` / `due_stage_distribution`（待复习）：已排期且非 `NEW` 重学的卡；学新阶段重学卡不计入。
- `new_cards`（待学习/学新队列规模）：待学新卡 + `NEW` 重学卡。
- `review_logs.learning_origin` 是评分时刻的卡片来源快照（评分前取值），用于统计与历史回溯。

`learning_origin` 经同步载荷（Bootstrap/复习会话 protobuf 与 JSON）与备份导出导入全链路传递。

> **2026-08-08 架构评审候选 2 落地**：排期状态统一经 `card/entity/SchedulingState` 值对象投影——`Card.getSchedulingState()`/`applySchedulingState()`，`CardResponse`/`ReviewCardResponse`/`BootstrapCard`/备份 JSON 四类出口都从它取排期字段，禁止逐字段散落读取。修复备份缺口：`BackupService.exportData` 曾漏导出 `learning_step`/`learning_origin`/`review_version`（导入却读取 `learning_origin`），恢复后 NEW 重学卡队列归属退化为 REVIEW 兜底、重学插位间距全丢；现导出/导入均经 `SchedulingState` 全字段 round-trip（旧备份缺键自动回退默认）。`CardResponse` 随之补充 `review_version`/`learning_origin`（JSON 卡片列表通道字段补齐，`new` 筛选仍由服务端 `filter=new` 计算）。

> **2026-08-08 架构评审候选 3 落地**：due/new 查询谓词单一化——`card/repository/CardQueryPredicates` 集中声明两种口径的 JPQL 与 native SQL 变体（`NEW_QUEUE` 学新队列 / `DUE_EXCLUDING_NEW` 复习队列与统计），`CardRepository` 9 处 `@Query` 全部拼接常量，前端 `offline_repository.dart` 收敛为 `_isNewCard`/`_isDueCard` 两函数（10+ 处调用点），两端注释互相引用。**修复口径 bug**：卡片列表 `filter=due` 原用派生查询未排除 NEW 重学卡，与「待复习」badge 计数（统计口径含排除）不一致，现改用 `DUE_EXCLUDING_NEW`。删除无调用死方法 `countNewByUserId`/`countDueToday`。后端全量 286 测试（含系统测试）、前端全量 228 测试通过。

> **2026-08-08 架构评审候选 4 落地**：统计口径收敛——`StatsService.getDeckCounters` 成为卡组计数唯一出口（`DeckCounters` DTO），`DeckService.toDeckResponse` 改调它并删除本类 6 项计数与 `distributionFromRows` 重复实现；模块依赖新增 `deck → stats`（仅 service 层，包级无环）。刷新点解析统一收口 `auth/util/UserRefreshTime.resolve`（兜底 04:00 原复制 4 份）。业务日边界权威定义写入 `DateUtils.calculateToday` javadoc（区间法 `[today@refresh, +1d)` 与 SQL 截断法 `(reviewed_at-refresh)::date` 两种等价写法，禁止第三种）。

> **2026-08-08 架构评审候选 5 落地**：排期公式单一数据源——前端新建 `shared/scheduling/scheduling_constants.dart`（间隔表 / maxStage / 3·5 阈值 / familiar·vague 间隔公式 / 2^n 插位偏移），此前间隔表在 `local_scheduling_engine.dart`、`review_card.dart`、`app/theme.dart`（业务常量混入 UI 间距类）三处副本，公式双份实现；现引擎与 `ReviewCard` 委托本类公式，`theme.dart` 不再持有排期常量（`stageLabels`/`stageName` 引用单一源），插位统一走 `relearningInsertOffset`（原前端 3 处 `1 << step`）。与后端 `SchedulingEngine.java` 为跨语言独立副本，改公式必须两端同步（由 `LocalSchedulingEngineTest` 与系统测试保障）。

## 7.1.2 统计一致性问题复盘（2026-08 生产故障）

### 现象

「今日复习」持续把「今日新学」（学新阶段重学评分）计入，复习卡/学习卡语义不清；统计页与今日页数字与服务器不一致，多次修复后仍复现。

### 根因（精确到行）

- 后端 `SyncProtoMapper.toReviewLog` **正确**填充 `learning_origin`；
- 前端 `lib/shared/proto/proto_mappers.dart` 的 **`reviewLogToMap` 漏映射 `learning_origin`**（`cardToMap`/`reviewCardToMap` 均有，唯独日志没有）→ 本地 Drift `local_review_logs.learning_origin` 恒 NULL；
- 本地 `OfflineRepository.getOverviewStats` 对 `learning_origin IS NULL` 兜底计入「今日复习」→ 学新重学评分（origin 本应为 `NEW`）全部误计；
- 生产前后端走 protobuf 内容协商，JSON 路径正常、protobuf 路径丢字段，故线上症状"玄学"。

### 实测证据（生产 API vs 真机本地 Drift）

| 指标 | 服务器 | 本地（修复前） | 本地（修复后） |
|---|---|---|---|
| 今日复习 reviewedToday | 31 | 149 | 31 |
| 今日新学 learnedToday | 123 | 123 | 123 |
| 待复习 dueToday | 0 | 1062（旧卡状态未同步） | 0 |
| 学新队列 new_cards | 4102 | 4625 | 4102 |

差值 118 = 当日学新重学评分数。修复后本地日志 `learning_origin` 分布与服务器一致（`NEW: 118`）。

### 修复与防回归

- `reviewLogToMap` 补充 `'learning_origin': log.hasLearningOrigin() ? log.learningOrigin : null`；新增回归测试 `frontend/test/proto_mappers_test.dart`。
- **防回归红线**：新增同步字段时，protobuf 路径（`proto_mappers.dart` 与重新生成的 `*.pb.dart`）与 JSON 路径必须同步覆盖；统计口径的 NULL 兜底会把"字段缺失"静默翻译成"复习"，宁可少算不可错算。
- **2026-08-08 架构评审候选 1 落地（机制化防回归）**：`proto_mappers.dart` 重构为声明式投影——映射键集合由生成代码 `BuilderInfo.info_.byIndex` 推导（新增 proto 字段自动进入映射，不再手写字面量键），值函数对未处理字段抛 `UnsupportedError`，`test/proto_mappers_test.dart` 的字段对账用例保证"加字段漏映射"在测试期直接红；同时收敛 `review_repository`/`sync_repository` 两份重复的 `_unsupported()` 为 `ApiClient.isProtoUnsupported`，并修复 `reviewSyncItemResultToMap` 内联映射遗漏 `card_id` 的问题。此后本红线的执行不再依赖人工对照。
- **存量用户处置**：修复只影响之后同步的数据；存量本地日志需触发「设置 → 以服务器数据为准」（`forceServerAuthoritative` → 全量 bootstrap 重灌）修正，发布 release 时应在更新说明引导。

### 已知限制

- **存量历史日志来源不可回填**：V15 前写入的 `review_logs` 无 `learning_origin` 概念（服务器与本地均无），按 `REVIEW` 兜底，无法区分学新/复习重学——属历史数据限制，非代码缺陷。
- **首页进度环为复习完成度口径**：进度环分母 `reviewed + due` 只含复习队列，不含学新队列——这是设计语义（新学是独立队列），非缺陷；记忆刻度展示的是「今日任务」全量（含学新），两者表达不同指标。

### 已修复（2026-08-08）

- `reviewLogToMap` 漏映射 `learning_origin`（本小节「根因」）。
- `_rateRemote` 在线评分插回重学卡丢失 `learningOrigin`/`reentryStage`：`RateResponse` 新增 `reentry_stage`/`learning_origin`（`ReviewService.toRateResponse` 与幂等分支填充），前端 `ReviewResult` 解析并用于插回（`review_provider.dart`），避免会话内再次评分时来源快照丢失与重学类型判定错误。配套：`frontend/test/models_test.dart` 重学字段解析断言；`docs/design/api.md` 评分接口响应补充字段。
- `proto_mappers.dart` 声明式投影重构（本小节「防回归」机制化）：消灭手写字面量键，漏映射由测试期 `UnsupportedError` 拦截；`reviewSyncItemResultToMap` 补上内联映射遗漏的 `card_id`；`review_repository`/`sync_repository` 的 `_unsupported()` 收敛为 `ApiClient.isProtoUnsupported`。

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

批量评分同步（`ReviewService.syncRatings`）使用批量锁：一次 `SELECT ... FOR UPDATE`（`CardRepository.findByIdInAndUserIdForUpdate`）锁住一批卡片，配合批量幂等检查（`ReviewLogRepository.findByUserIdAndClientRequestIdIn`）与 `saveAll` 批量落库，N 条评分从 4N+ 条 SQL 降到约 5 条；`refresh_time` 在循环外只取一次，避免每条评分点查 `users` 表。

## 9. 部署与运行时调优

### 9.1 连接池（HikariCP，`application-prod.properties`）

- 池大小按 CPU 核数 × 2~4 估算（默认 `maximum-pool-size=16`，`minimum-idle=4`，可通过 `HIKARI_MAX_POOL_SIZE` 环境变量覆盖）。
- `connection-timeout=30s`、`max-lifetime=30min`。
- 连接初始化时执行 `SET statement_timeout = '30s'`（`connection-init-sql`），任何失控查询最多 30 秒被终止，避免无限占住连接池。

### 9.2 JDBC 批处理（`application.properties`）

`hibernate.jdbc.batch_size=50` + `order_inserts`/`order_updates`，批量导入（`CardImportService`/`BackupService.importData`）与批量评分同步合并为批次 INSERT/UPDATE，减少网络往返。

### 9.3 PostgreSQL 容器参数（`docker-compose.prod.yaml`）

以下按 4GB 内存服务器估算，实际按机器内存等比调整（`shared_buffers ≈ 25%`、`effective_cache_size ≈ 75%`）：

| 参数 | 值 | 说明 |
|------|-----|------|
| shared_buffers | 1GB | 共享缓冲区 |
| effective_cache_size | 3GB | 优化器缓存估算 |
| work_mem | 16MB | 排序/哈希内存 |
| maintenance_work_mem | 256MB | 建索引/清理 |
| wal_buffers | 16MB | WAL 缓冲 |
| checkpoint_completion_target | 0.9 | 平滑检查点 |
| autovacuum_vacuum_scale_factor | 0.05 | 更积极的 autovacuum |
| autovacuum_analyze_scale_factor | 0.02 | 更积极的 analyze |
| shared_preload_libraries | pg_stat_statements | 慢查询监控 |
| pg_stat_statements.max / track | 10000 / all | 监控采样 |

`shm_size: 1gb`（macOS/WSL 下默认 `/dev/shm` 仅 64MB，可能限制并行查询；Linux 上无副作用）。

### 9.4 慢查询监控

启用 `pg_stat_statements` 后（需要重启容器）：

```sql
-- Top 慢查询（按平均执行时间）
SELECT query, calls, mean_exec_time, max_exec_time, rows
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 20;
```

验证模板见 testing.md §数据库性能验证。