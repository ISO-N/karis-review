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

- **前后端分离**：Flutter 客户端仅负责 UI 渲染，无本地业务数据存储
- **RESTful API**：客户端与服务端通过 HTTP/JSON 通信
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
│   └── OpenApiConfig.java               # OpenAPI 3 + JWT Bearer 配置
│
├── common/
│   ├── exception/
│   │   ├── GlobalExceptionHandler.java  # 全局异常处理
│   │   └── BusinessException.java       # 业务异常
│   ├── dto/
│   │   └── ApiResponse.java             # 统一响应格式
│   └── util/
│       └── DateUtils.java               # 日期工具
│
├── auth/
│   ├── controller/AuthController.java
│   ├── service/AuthService.java
│   ├── entity/User.java
│   ├── repository/UserRepository.java
│   ├── dto/
│   │   ├── RegisterRequest.java
│   │   ├── LoginRequest.java
│   │   └── LoginResponse.java
│   └── jwt/
│       ├── JwtProvider.java
│       └── JwtAuthenticationFilter.java
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
│   ├── service/CardService.java
│   ├── entity/Card.java
│   ├── repository/CardRepository.java
│   └── dto/
│       ├── CardCreateRequest.java
│       ├── CardUpdateRequest.java
│       └── CardResponse.java
│
├── review/
│   ├── controller/ReviewController.java
│   ├── service/
│   │   ├── ReviewService.java
│   │   └── SchedulingEngine.java       # 排期算法核心
│   ├── entity/ReviewLog.java
│   ├── repository/ReviewLogRepository.java
│   └── dto/
│       ├── ReviewCardResponse.java
│       └── RateRequest.java
│
├── stats/
│   ├── controller/StatsController.java
│   ├── service/StatsService.java
│   └── dto/
│       ├── OverviewStatsResponse.java
│       └── TrendStatsResponse.java
│
├── backup/
│   ├── controller/BackupController.java
│   ├── service/BackupService.java
│   └── entity/BackupSnapshot.java
│
└── settings/
    ├── controller/SettingsController.java
    ├── service/SettingsService.java
    └── dto/
        └── UserSettingsResponse.java
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
│   │   ├── api_client.dart              # Dio HTTP 客户端
│   │   └── api_endpoints.dart           # API 端点常量
│   ├── widgets/
│   │   ├── loading_widget.dart
│   │   └── error_widget.dart
│   └── utils/
│       └── date_utils.dart
│
├── auth/
│   ├── auth_provider.dart               # Riverpod Provider
│   ├── auth_repository.dart             # API 调用
│   ├── pages/
│   │   ├── login_page.dart
│   │   └── register_page.dart
│   └── models/
│       ├── login_request.dart
│       └── login_response.dart
│
├── deck/
│   ├── deck_provider.dart
│   ├── deck_repository.dart
│   ├── pages/
│   │   └── deck_list_page.dart
│   └── models/
│       └── deck.dart
│
├── card/
│   ├── card_provider.dart
│   ├── card_repository.dart
│   ├── pages/
│   │   └── card_list_page.dart
│   │   └── card_edit_page.dart
│   └── models/
│       └── card.dart
│
├── review/
│   ├── review_provider.dart
│   ├── review_repository.dart
│   ├── pages/
│   │   └── review_page.dart
│   └── models/
│       └── review_card.dart
│
├── stats/
│   ├── stats_provider.dart
│   ├── stats_repository.dart
│   ├── pages/
│   │   └── stats_page.dart
│   └── models/
│       └── stats.dart
│
└── settings/
    ├── settings_provider.dart
    ├── settings_repository.dart
    └── pages/
        └── settings_page.dart
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
- 受保护 Controller 用 `@SecurityRequirement` 声明 `bearerAuth` JWT 安全方案；登录/注册接口不要求。
- `SecurityConfig` 放行 `/v3/api-docs/**`、`/swagger-ui/**`、`/swagger-ui.html`。
- 生产环境使用 `prod` profile 时关闭文档。

## 6. 模块间依赖关系
```
auth ──────► common
deck ──────► common
card ──────► deck, common
review ────► card, deck, common  (依赖 SchedulingEngine)
stats ─────► review, deck, common
backup ────► deck, card, review, common  (全量导出)
settings ──► common
```

- 每个模块内部按 `controller → service → repository` 单向依赖
- 模块间**严禁循环依赖**（review 可调用 card 的 Service，但 card 不可反向调用 review）
- `SchedulingEngine` 作为独立的核心算法类，零外部依赖，便于单元测试