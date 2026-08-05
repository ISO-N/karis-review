# 数据库设计 — Karis Review

## 1. 概述

- **数据库类型**：PostgreSQL 16
- **数据库名**：`karis_review`
- **字符集**：`UTF-8` (PostgreSQL 默认)
- **迁移工具**：Flyway
- **命名规范**：
  - 表名：`snake_case` 复数形式（如 `users`, `decks`, `cards`）
  - 字段名：`snake_case`
  - 主键：`id`（UUID 类型）
  - 外键：`{关联表}_id`（如 `user_id`, `deck_id`）
  - 时间戳：`created_at`, `updated_at`

## 2. 实体关系图（ERD）

```
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│    users     │       │    decks     │       │    cards     │
│──────────────│       │──────────────│       │──────────────│
│ id (PK)      │──1:N──│ user_id (FK) │──1:N──│ deck_id (FK) │
│ email        │       │ id (PK)      │       │ user_id (FK) │
│ password_hash│       │ name         │       │ id (PK)      │
│ refresh_time │       │ created_at   │       │ front        │
│ created_at   │       │ updated_at   │       │ back         │
│ updated_at   │       └──────────────┘       │ stage        │
└──────────────┘                              │ consecutive_ │
       │                                      │  familiar    │
       │                                      │ next_review_ │
       │                                      │  date        │
       │                                      │ learning_    │
       │                                      │  mode        │
       │                                      │ reentry_     │
       │                                      │  stage       │
       │                                      │ created_at   │
       │                                      │ updated_at   │
       │                                      └──────┬───────┘
       │                                             │
       │              ┌──────────────────┐            │
       │              │  review_logs     │            │
       │              │──────────────────│            │
       └──────1:N─────│ user_id (FK)     │            │
                      │ card_id (FK)     │◄────1:N───┘
                      │ id (PK)          │
                      │ rating           │
                      │ stage_before     │
                      │ stage_after      │
                      │ reviewed_at      │
                      └──────────────────┘

       ┌──────────────────┐
       │  backup_         │
       │  snapshots       │
       │──────────────────│
       │ user_id (FK)     │
       │ id (PK)          │
       │ data (JSONB)     │
       │ created_at       │
       └──────────────────┘
```

## 3. 表结构

### 3.1 users

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK, DEFAULT gen_random_uuid() | 主键 |
| email | VARCHAR(255) | NOT NULL, UNIQUE | 邮箱 |
| password_hash | VARCHAR(255) | NOT NULL | bcrypt 密码哈希 |
| refresh_time | TIME | NOT NULL, DEFAULT '04:00:00' | 每日刷新时间 |
| created_at | TIMESTAMP | NOT NULL, DEFAULT NOW() | 注册时间 |
| updated_at | TIMESTAMP | NOT NULL, DEFAULT NOW() | 更新时间 |

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    refresh_time TIME NOT NULL DEFAULT '04:00:00',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

### 3.2 decks

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK, DEFAULT gen_random_uuid() | 主键 |
| user_id | UUID | NOT NULL, FK → users(id) ON DELETE CASCADE | 所属用户 |
| name | VARCHAR(255) | NOT NULL | 卡组名称 |
| created_at | TIMESTAMP | NOT NULL, DEFAULT NOW() | 创建时间 |
| updated_at | TIMESTAMP | NOT NULL, DEFAULT NOW() | 更新时间 |

```sql
CREATE TABLE decks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_decks_user_id ON decks(user_id);
```

### 3.3 cards

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK, DEFAULT gen_random_uuid() | 主键 |
| deck_id | UUID | NOT NULL, FK → decks(id) ON DELETE CASCADE | 所属卡组 |
| user_id | UUID | NOT NULL, FK → users(id) ON DELETE CASCADE | 所属用户 |
| front | TEXT | NOT NULL | 正面内容（富文本/LaTeX/代码） |
| back | TEXT | NOT NULL | 反面内容（富文本/LaTeX/代码） |
| stage | INTEGER | NOT NULL, DEFAULT 0 | 当前阶段 (0-8) |
| consecutive_familiar | INTEGER | NOT NULL, DEFAULT 0 | 重学阶段连续 Familiar 计数 |
| next_review_date | DATE | NULL | 下次复习日期（NULL 表示学习中） |
| learning_mode | BOOLEAN | NOT NULL, DEFAULT FALSE | 是否处于重学模式 |
| reentry_stage | INTEGER | NULL | VAGUE 重学完成后需回到的 Stage |
| learning_step | INTEGER | NOT NULL, DEFAULT 0 | 重学队列插入间距步数（2^n） |
| review_version | BIGINT | NOT NULL, DEFAULT 0 | 评分锁版本，任何评分/内容更新自动递增 |
| updated_at | TIMESTAMP | NOT NULL, DEFAULT NOW() | 更新时间 |

```sql
CREATE TABLE cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deck_id UUID NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    front TEXT NOT NULL,
    back TEXT NOT NULL,
    stage INTEGER NOT NULL DEFAULT 0,
    consecutive_familiar INTEGER NOT NULL DEFAULT 0,
    next_review_date DATE NULL,
    learning_mode BOOLEAN NOT NULL DEFAULT FALSE,
    reentry_stage INTEGER NULL,
    learning_step INTEGER NOT NULL DEFAULT 0,
    review_version BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_cards_deck_id ON cards(deck_id);
CREATE INDEX idx_cards_user_id ON cards(user_id);
CREATE INDEX idx_cards_next_review ON cards(user_id, next_review_date)
    WHERE next_review_date IS NOT NULL;
```

### 3.4 review_logs

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK, DEFAULT gen_random_uuid() | 主键 |
| card_id | UUID | NOT NULL, FK → cards(id) ON DELETE CASCADE | 被评分的卡片 |
| user_id | UUID | NOT NULL, FK → users(id) ON DELETE CASCADE | 所属用户 |
| rating | VARCHAR(10) | NOT NULL, CHECK IN ('FORGET','VAGUE','FAMILIAR') | 评分 |
| stage_before | INTEGER | NOT NULL | 复习前的 Stage |
| stage_after | INTEGER | NOT NULL | 复习后的 Stage |
| is_new_card | BOOLEAN | NOT NULL, DEFAULT FALSE | 评分时是否处于新卡状态（Stage 0 且非重学） |
| client_request_id | VARCHAR(64) | NULL | 客户端幂等请求 ID，同一用户内唯一 |

```sql
CREATE TABLE review_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating VARCHAR(10) NOT NULL CHECK (rating IN ('FORGET', 'VAGUE', 'FAMILIAR')),
    stage_before INTEGER NOT NULL,
    stage_after INTEGER NOT NULL,
    is_new_card BOOLEAN NOT NULL DEFAULT FALSE,
    client_request_id VARCHAR(64) NULL,
    reviewed_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_review_logs_card_id ON review_logs(card_id);
CREATE INDEX idx_review_logs_user_id ON review_logs(user_id);
CREATE INDEX idx_review_logs_reviewed_at ON review_logs(user_id, reviewed_at);
CREATE UNIQUE INDEX idx_review_logs_user_client_request
    ON review_logs(user_id, client_request_id)
    WHERE client_request_id IS NOT NULL;
```

### 3.5 review_sessions 与 review_queue_items

`review_sessions` 保存动态复习队列快照：id、user_id、mode、deck_id、batch_size、total_count、created_at、expires_at。

`review_queue_items` 保存快照中的有序卡片位置：session_id、user_id、position、card_id，`(session_id, position)` 唯一。

### 3.6 backup_snapshots
| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK, DEFAULT gen_random_uuid() | 主键 |
| user_id | UUID | NOT NULL, FK → users(id) ON DELETE CASCADE | 所属用户 |
| data | JSONB | NOT NULL | 用户全量数据快照 |
| created_at | TIMESTAMP | NOT NULL, DEFAULT NOW() | 创建时间 |

```sql
CREATE TABLE backup_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    data JSONB NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_backup_snapshots_user_id ON backup_snapshots(user_id);
```

### 3.7 sync_events

`sync_events` 保存用户数据变更事件，用于前端增量同步。

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK, DEFAULT gen_random_uuid() | 主键 |
| user_id | UUID | NOT NULL, FK → users(id) ON DELETE CASCADE | 所属用户 |
| entity_type | VARCHAR(20) | NOT NULL | 实体类型：decks/cards/review_logs/users |
| entity_id | UUID | NOT NULL | 实体 ID |
| event_type | VARCHAR(10) | NOT NULL | CREATED/UPDATED/DELETED |
| event_seq | BIGSERIAL | NOT NULL, UNIQUE | 单调事件游标 |
| occurred_at | TIMESTAMP | NOT NULL, DEFAULT NOW() | 发生时间 |

数据库触发器自动写入事件，覆盖卡组、卡片、复习日志、用户设置变更；删除用户时级联删除事件，不再为用户删除写入事件。

### 3.8 user_logs

`user_logs` 保存脱敏后的操作日志，用于用户可查看的诊断信息。

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK, DEFAULT gen_random_uuid() | 主键 |
| user_id | UUID | NOT NULL, FK → users(id) ON DELETE CASCADE | 所属用户 |
| level | VARCHAR(10) | NOT NULL | INFO/WARN/ERROR |
| category | VARCHAR(50) | NOT NULL | AUTH/REVIEW/CARD/DECK/BACKUP/SETTINGS/SYNC/SYSTEM 等 |
| message | TEXT | NOT NULL | 脱敏消息 |
| details | JSONB | NULL | 结构化详情 |
| created_at | TIMESTAMP | NOT NULL, DEFAULT NOW() | 创建时间 |

日志默认保留 30 天，由 `UserLogService.cleanupOldLogs()` 每日清理。

### 3.9 email_verification_codes

`email_verification_codes` 保存邮箱验证码，用于注册邮箱验证（purpose=REGISTER）与找回密码（purpose=RESET）。

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK, DEFAULT gen_random_uuid() | 主键 |
| email | VARCHAR(255) | NOT NULL | 目标邮箱 |
| purpose | VARCHAR(16) | NOT NULL | REGISTER（注册验证）/ RESET（找回密码） |
| code | VARCHAR(6) | NOT NULL | 6 位数字验证码 |
| expires_at | TIMESTAMP | NOT NULL | 过期时间（15 分钟） |
| used | BOOLEAN | NOT NULL, DEFAULT FALSE | 是否已消费 |
| attempt_count | INTEGER | NOT NULL, DEFAULT 0 | 校验失败次数（超 10 次作废） |
| created_at | TIMESTAMP | NOT NULL, DEFAULT NOW() | 创建时间 |

同一邮箱同一用途 60 秒内只允许发一次（由 service 层检查最近一条未过期记录）。

## 4. Flyway 迁移脚本结构
src/main/resources/db/migration/
├── V2__create_decks_table.sql
├── V3__create_cards_table.sql
├── V4__create_review_logs_table.sql
├── V5__create_backup_snapshots_table.sql
├── V6__add_learning_step_to_cards.sql
├── V7__add_new_card_flag_to_review_logs.sql
├── V8__add_review_lock_and_sessions.sql
├── V9__add_sync_events.sql
├── V10__add_card_search_indexes.sql
├── V11__create_user_logs.sql
├── V12__create_email_verification_codes.sql
├── V13__performance_optimizations.sql       # 索引 + 触发器优化 + 清理策略
└── V14__fix_sync_trigger_existence_check.sql # 修复 V13 触发器的级联删除外键问题

迁移约定：
- `ddl-auto=none`，schema 完全由 Flyway 管理；改表必须新增迁移脚本，不能修改已提交脚本。
- 生产大表建索引建议手动执行 `CREATE INDEX CONCURRENTLY`（不能放在事务内），脚本中的索引均带 `IF NOT EXISTS` 可安全跳过。

## 4.1 索引设计

### 全部索引清单

| 表 | 索引 | 服务查询 |
|----|------|----------|
| users | `email` (UNIQUE) | 登录/注册按邮箱定位 |
| decks | `idx_decks_user_id (user_id)` | 按用户查卡组 |
| cards | `idx_cards_deck_id (deck_id)` | 卡组下卡片 |
| cards | `idx_cards_user_id (user_id)` | 按用户查卡片 |
| cards | `idx_cards_next_review (user_id, next_review_date) WHERE next_review_date IS NOT NULL` | **复习队列**：due 卡片 + 排序（V3） |
| cards | `idx_cards_deck_created (deck_id, created_at)` | 卡片列表分页（all/new/learning 筛选共用排序，V13） |
| cards | `idx_cards_user_stage_learning (user_id, stage, learning_mode, created_at)` | 新卡队列 + 统计聚合 Index Only Scan（V13） |
| cards | `idx_cards_deck_due (deck_id, next_review_date) WHERE next_review_date IS NOT NULL` | 卡组 due 筛选（V13） |
| cards | `idx_cards_user_learning_due (user_id, next_review_date) WHERE learning_mode AND next_review_date IS NOT NULL` | 重学队列（V13） |
| cards | `idx_cards_front_search_trgm` / `idx_cards_back_search_trgm`（GIN trgm） | 卡片正反面 `%keyword%` 搜索（V10） |
| review_logs | `idx_review_logs_card_id (card_id)` | 按卡查日志 |
| review_logs | `idx_review_logs_user_id (user_id)` | 按用户查日志 |
| review_logs | `idx_review_logs_reviewed_at (user_id, reviewed_at)` | 当日统计/趋势 |
| review_logs | `idx_review_logs_user_card (user_id, card_id)` | 卡组今日复习统计 semi-join（V13） |
| review_logs | `idx_review_logs_user_client_request` (UNIQUE 部分) | 评分幂等 |
| sync_events | `idx_sync_events_seq` (UNIQUE) / `idx_sync_events_user_seq (user_id, event_seq)` | 增量游标 |
| review_sessions / review_queue_items | session 相关索引 | 会话分页 |
| backup_snapshots / email_verification_codes | user_id / expires_at | 查询与清理 |
| user_logs | user_id / created_at | 查询与清理 |

### 设计要点

- **索引可反向扫描**：`ORDER BY created_at DESC` 无需单独建 DESC 索引，`(deck_id, created_at)` 一条同时服务 ASC/DESC。
- **复习队列排序必须按列而非表达式**：`ORDER BY (next_review_date - :today) DESC` 等价于 `ORDER BY next_review_date ASC`（today 是常量），后者才能命中 `idx_cards_next_review` 消除 Sort。`CardRepository.findDueCards` 已按此实现。
- **统计走 Index Only Scan**：`StatsService.getOverview` 用单条原生聚合 `aggregateOverviewStats`（按 stage 分组 + `FILTER` 计数），配合 `idx_cards_user_stage_learning` 一条索引覆盖全部统计，替代原来 7+ 条独立 COUNT。
- **trgm 搜索局限**：`%pattern%` 中 pattern 少于 3 个字符时 GIN trgm 索引失效，退化为顺序扫描；短词搜索在应用层限制长度。
- **索引写放大控制**：部分索引（`WHERE ...`）只维护有价值的子集，避免为全表维护低频查询索引。

## 4.2 数据保留与定期清理

| 表 | 保留策略 | 清理任务 | 调度 |
|----|----------|----------|------|
| user_logs | 30 天 | `UserLogService.cleanupOldLogs()` | 每天 03:00 |
| sync_events | 60 天 | `SyncService.cleanupOldSyncEvents()` | 每天 03:30 |
| email_verification_codes | 过期后 7 天 | `PasswordResetCodeService.cleanupExpiredCodes()` | 每天 03:40 |
| backup_snapshots | 每用户最近 7 份 | `BackupService.cleanupOldSnapshots()` | 每天 03:50 |

> ⚠️ `sync_events` 是写放大最严重的表（每次评分 2 条）。清理后，长时间未同步的客户端增量游标会失效，`SyncService.deltaBootstrap` 通过 `minSeq`/`latestSeq` 检查自动降级为全量同步，不破坏增量一致性。

## 4.3 sync_events 触发器说明

`record_sync_event()` 触发器在 decks/cards/review_logs/users 变更时写入事件：

- **INSERT/UPDATE**：外键保证用户存在，直接写事件（零额外查询）。
- **DELETE（含 users 表自身）**：必须检查 `EXISTS (SELECT 1 FROM users ...)`——`DELETE FROM users` 的级联删除会在用户行删除后执行子表 AFTER DELETE 触发器，此时写事件会违反 `sync_events_user_id_fkey`（V14 修复，V13 曾因移除该检查导致系统测试全量失败）。

## 5. 关键查询说明

### 5.1 获取今日待复习卡片

```sql
-- 根据用户的 refresh_time 计算"今天"的范围（业务时区为 Asia/Shanghai）
-- 假设 refresh_time = '04:00:00'
-- 当前时间 2025-08-02 10:00:00 → 今天范围: 2025-08-02 04:00:00 ~ 2025-08-03 04:00:00
-- 当前时间 2025-08-02 03:00:00 → 今天范围: 2025-08-01 04:00:00 ~ 2025-08-02 04:00:00

SELECT c.* FROM cards c
WHERE c.user_id = :userId
  AND c.next_review_date IS NOT NULL
  AND c.next_review_date <= :todayDate  -- 基于 refresh_time 计算的日期
  AND c.learning_mode = FALSE
ORDER BY c.next_review_date ASC;
```

### 5.2 获取待学习的新卡片

```sql
SELECT c.* FROM cards c
WHERE c.user_id = :userId
  AND c.stage = 0
  AND c.learning_mode = FALSE
ORDER BY c.created_at ASC;
```

### 5.3 卡片正反面搜索

```sql
SELECT c.* FROM cards c
WHERE c.deck_id = :deckId
  AND (LOWER(c.front) LIKE LOWER(:pattern) ESCAPE '\'
       OR LOWER(c.back) LIKE LOWER(:pattern) ESCAPE '\')
ORDER BY c.created_at ASC;
```

`V10` 启用 `pg_trgm`，并为 `lower(front)`、`lower(back)` 建立 GIN 索引以加速 `%keyword%` 搜索。

### 5.4 备份导出数据格式

```json
{
  "exported_at": "2025-08-02T10:00:00Z",
  "user": {
    "email": "user@example.com",
    "refresh_time": "04:00:00"
  },
  "decks": [
    {
      "name": "日语N5",
      "cards": [
        {
          "front": "ありがとう",
          "back": "谢谢",
          "stage": 3,
          "consecutive_familiar": 0,
          "next_review_date": "2025-08-06",
          "learning_mode": false,
          "reentry_stage": null
        }
      ]
    }
  ],
  "review_logs": [
    {
      "card_front": "ありがとう",
      "rating": "FAMILIAR",
      "stage_before": 2,
      "stage_after": 3,
      "is_new_card": false,
      "reviewed_at": "2025-08-01T12:00:00Z"
    }
  ]
}
```