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

## 4. Flyway 迁移脚本结构
src/main/resources/db/migration/
├── V1__create_users_table.sql
├── V2__create_decks_table.sql
├── V3__create_cards_table.sql
├── V4__create_review_logs_table.sql
├── V5__create_backup_snapshots_table.sql
├── V6__add_learning_step_to_cards.sql
├── V7__add_new_card_flag_to_review_logs.sql
├── V8__add_review_lock_and_sessions.sql
├── V9__add_sync_events.sql
└── V10__add_card_search_indexes.sql

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