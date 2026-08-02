# 接口设计 — Karis Review

## 1. 通用约定

### 1.1 基础 URL

```
开发环境: http://localhost:8080/api
生产环境: https://review.kariscode.top/api

### 1.2 统一响应格式

所有 API 返回统一结构：

```json
{
  "code": 200,
  "message": "success",
  "data": { ... }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| code | int | HTTP 状态码（200/400/401/403/404/500） |
| message | string | 提示信息 |
| data | object/null | 业务数据 |

### 1.3 错误响应

```json
{
  "code": 400,
  "message": "邮箱已被注册",
  "data": null
}
```

### 1.4 认证方式

- 使用 JWT（JSON Web Token）
- 请求头格式：`Authorization: Bearer <token>`
- Token 有效期：7 天
- 注册/登录接口不需要认证，其余接口均需认证

### 1.5 分页

列表接口支持分页，请求参数：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| page | int | 0 | 页码（从 0 开始） |
| size | int | 20 | 每页条数 |

响应格式：

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "content": [ ... ],
    "page": 0,
    "size": 20,
    "total_elements": 100,
    "total_pages": 5
  }
}
```

---

## 2. 认证模块

### POST /api/auth/register

注册新用户。

**Request Body:**

```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| email | string | 是 | 邮箱地址 |
| password | string | 是 | 密码（6-128 位） |

**Response (200):**

```json
{
  "code": 200,
  "message": "注册成功",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "user": {
      "id": "uuid",
      "email": "user@example.com"
    }
  }
}
```

**错误码：** 400（邮箱已注册/邮箱格式无效/密码太短）

---

### POST /api/auth/login

用户登录。

**Request Body:**

```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**Response (200):**

```json
{
  "code": 200,
  "message": "登录成功",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "user": {
      "id": "uuid",
      "email": "user@example.com"
    }
  }
}
```

**错误码：** 401（邮箱或密码错误）

---

### POST /api/auth/logout

登出（客户端丢弃 Token 即可，服务端可选做 Token 黑名单）。

**Headers:** `Authorization: Bearer <token>`

**Response (200):**

```json
{
  "code": 200,
  "message": "已登出",
  "data": null
}
```

---

## 3. 用户设置模块

### GET /api/settings

获取当前用户设置。

**Headers:** `Authorization: Bearer <token>`

**Response (200):**

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "email": "user@example.com",
    "refresh_time": "04:00:00"
  }
}
```

---

### PUT /api/settings

更新用户设置。

**Request Body:**

```json
{
  "refresh_time": "03:00:00"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| refresh_time | string | 是 | 每日刷新时间，格式 HH:mm:ss |

**Response (200):**

```json
{
  "code": 200,
  "message": "设置已更新",
  "data": {
    "email": "user@example.com",
    "refresh_time": "03:00:00"
  }
}
```

---

## 4. 牌组模块

### GET /api/decks

获取当前用户所有牌组列表。

**Headers:** `Authorization: Bearer <token>`

**Response (200):**

```json
{
  "code": 200,
  "message": "success",
  "data": [
    {
      "id": "uuid",
      "name": "日语N5",
      "card_count": 42,
      "due_count": 5,
      "new_count": 3,
      "mastered_count": 20,
      "stage_distribution": {
        "0": 5, "1": 8, "2": 6, "3": 7, "4": 5,
        "5": 4, "6": 3, "7": 2, "8": 2
      },
      "due_stage_distribution": {
        "0": 1, "1": 2, "2": 1, "3": 1, "4": 0,
        "5": 0, "6": 0, "7": 0, "8": 0
      },
      "created_at": "2025-07-01T10:00:00Z"
    }
  ]
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| card_count | int | 牌组内卡片总数 |
| due_count | int | 今日待复习卡片数 |
| new_count | int | 可学习的新卡数（Stage 0 且非重学） |
| mastered_count | int | 已掌握卡片数（Stage ≥ 5） |
| stage_distribution | map<string,int> | 各阶段卡片数量分布（0-8） |
| due_stage_distribution | map<string,int> | 今日到期卡片阶段分布（0-8） |

---

### POST /api/decks

创建新牌组。

**Request Body:**

```json
{
  "name": "日语N5"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | string | 是 | 牌组名称（1-100 字符） |

**Response (200):**

```json
{
  "code": 200,
  "message": "牌组已创建",
  "data": {
    "id": "uuid",
    "name": "日语N5",
    "card_count": 0,
    "due_count": 0,
    "new_count": 0,
    "mastered_count": 0,
    "stage_distribution": {
      "0": 0, "1": 0, "2": 0, "3": 0, "4": 0,
      "5": 0, "6": 0, "7": 0, "8": 0
    },
    "due_stage_distribution": {
      "0": 0, "1": 0, "2": 0, "3": 0, "4": 0,
      "5": 0, "6": 0, "7": 0, "8": 0
    },
    "created_at": "2025-08-01T10:00:00Z"
  }
}
```

---

### PUT /api/decks/{deckId}

重命名牌组。

**Request Body:**

```json
{
  "name": "日语N5-改"
}
```

**Response (200):**

```json
{
  "code": 200,
  "message": "牌组已更新",
  "data": {
    "id": "uuid",
    "name": "日语N5-改",
    "card_count": 42,
    "due_count": 5,
    "new_count": 3,
    "mastered_count": 20,
    "stage_distribution": {
      "0": 5, "1": 8, "2": 6, "3": 7, "4": 5,
      "5": 4, "6": 3, "7": 2, "8": 2
    },
    "due_stage_distribution": {
      "0": 1, "1": 2, "2": 1, "3": 1, "4": 0,
      "5": 0, "6": 0, "7": 0, "8": 0
    },
    "created_at": "2025-07-01T10:00:00Z"
  }
}
```

---

### DELETE /api/decks/{deckId}

删除牌组（级联删除牌组内所有卡片及复习记录）。

**Headers:** `Authorization: Bearer <token>`

**Response (200):**

```json
{
  "code": 200,
  "message": "牌组已删除",
  "data": null
}
```

**错误码：** 404（牌组不存在或不属于当前用户）

---

## 5. 卡片模块

### GET /api/decks/{deckId}/cards

获取牌组内所有卡片列表。

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| page | int | 0 | 页码 |
| size | int | 20 | 每页条数 |
| filter | string | all | 卡片筛选：`all`、`due`、`learning` |

**Response (200):**

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "content": [
      {
        "id": "uuid",
        "deck_id": "uuid",
        "front": "ありがとう",
        "back": "谢谢",
        "stage": 3,
        "next_review_date": "2025-08-06",
        "learning_mode": false,
        "consecutive_familiar": 0,
        "learning_step": 0,
        "reentry_stage": null,
        "learning_goal": null,
        "due": false,
        "created_at": "2025-07-01T10:00:00Z"
      }
    ],
    "page": 0,
    "size": 20,
    "total_elements": 42,
    "total_pages": 3
  }
}
```

---

### POST /api/decks/{deckId}/cards

创建新卡片。

**Request Body:**

```json
{
  "front": "ありがとう",
  "back": "谢谢"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| front | string | 是 | 正面内容（富文本/LaTeX/代码） |
| back | string | 是 | 反面内容（富文本/LaTeX/代码） |

**Response (200):**

```json
{
  "code": 200,
  "message": "卡片已创建",
  "data": {
    "id": "uuid",
    "deck_id": "uuid",
    "front": "ありがとう",
    "back": "谢谢",
    "stage": 0,
    "next_review_date": null,
    "learning_mode": false,
    "consecutive_familiar": 0,
    "learning_step": 0,
    "reentry_stage": null,
    "learning_goal": null,
    "due": false,
    "created_at": "2025-08-01T10:00:00Z"
  }
}
```

---

### PUT /api/cards/{cardId}

编辑卡片内容。

**Request Body:**

```json
{
  "front": "ありがとうございます",
  "back": "谢谢（礼貌形）"
}
```

**Response (200):**

```json
{
  "code": 200,
  "message": "卡片已更新",
  "data": { ... }
}
```

---

### DELETE /api/cards/{cardId}

删除卡片。

**Headers:** `Authorization: Bearer <token>`

**Response (200):**

```json
{
  "code": 200,
  "message": "卡片已删除",
  "data": null
}
```

---

## 6. 复习模块

### GET /api/review/due

获取今日待复习卡片列表。

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| deck_id | UUID | null | 可选，按牌组筛选 |

**Response (200):**

```json
{
  "code": 200,
  "message": "success",
  "data": [
    {
      "id": "uuid",
      "deck_id": "uuid",
      "front": "ありがとう",
      "back": "谢谢",
      "stage": 3,
      "learning_mode": false,
      "consecutive_familiar": 0,
      "learning_goal": 5,
      "reentry_stage": null,
      "next_review_date": "2025-08-02",
      "current_interval_days": 4,
      "familiar_interval_days": 7,
      "vague_interval_days": 4
    }
  ]
}
```

> 复习队列中**处于重学模式**的卡片（FORGET/VAGUE 后以 2^n 间距插入的卡片）也会出现在此列表中。

---

### GET /api/review/new

获取待学习的新卡片列表（Stage 0 且未进入学习模式）。

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| deck_id | UUID | null | 可选，按牌组筛选 |
| limit | int | 10 | 每次最多取多少张新卡 |

**Response (200):**

```json
{
  "code": 200,
  "message": "success",
  "data": [
    {
      "id": "uuid",
      "deck_id": "uuid",
      "front": "新しい単語",
      "back": "新单词",
      "stage": 0,
      "learning_mode": false,
      "consecutive_familiar": 0,
      "learning_goal": 5,
      "reentry_stage": null,
      "next_review_date": null,
      "current_interval_days": 0,
      "familiar_interval_days": 1,
      "vague_interval_days": 0
    }
  ]
}
```

---

### POST /api/review/{cardId}/rate

对卡片进行评分。

**Headers:** `Authorization: Bearer <token>`

**Request Body:**

```json
{
  "rating": "FAMILIAR"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| rating | string | 是 | 枚举值：`FORGET`, `VAGUE`, `FAMILIAR` |

**Response (200):**

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "card_id": "uuid",
    "rating": "FAMILIAR",
    "stage_before": 3,
    "stage_after": 4,
    "next_review_date": "2025-08-08",
    "learning_mode": false,
    "consecutive_familiar": 0,
    "next_interval_days": 7
  }
}
```

| 返回字段 | 类型 | 说明 |
|----------|------|------|
| stage_before | int | 评分前的阶段 |
| stage_after | int | 评分后的阶段 |
| next_review_date | string/date | 下次复习日期 |
| learning_mode | bool | 是否仍在重学模式 |
| consecutive_familiar | int | 当前连续 Familiar 计数 |
| next_interval_days | int | 本次评分后的下次复习间隔天数（重学中为 0） |

**可能的业务逻辑返回：**

**场景 1：** 点 Familiar → 正常进入下一阶段

```json
{
  "card_id": "uuid",
  "rating": "FAMILIAR",
  "stage_before": 3,
  "stage_after": 4,
  "next_review_date": "2025-08-08",
  "learning_mode": false,
  "consecutive_familiar": 0,
  "next_interval_days": 7
}
```

**场景 2：** 点 FORGET → 进入重学模式

```json
{
  "card_id": "uuid",
  "rating": "FORGET",
  "stage_before": 4,
  "stage_after": 0,
  "next_review_date": null,
  "learning_mode": true,
  "consecutive_familiar": 0,
  "next_interval_days": 0
}
```

**场景 3：** 重学中点 Familiar，累计 3/5 次

```json
{
  "card_id": "uuid",
  "rating": "FAMILIAR",
  "stage_before": 0,
  "stage_after": 0,
  "next_review_date": null,
  "learning_mode": true,
  "consecutive_familiar": 2,
  "next_interval_days": 0
}
```

**场景 4：** 重学中集满 5 次 Familiar → 脱离重学

```json
{
  "card_id": "uuid",
  "rating": "FAMILIAR",
  "stage_before": 0,
  "stage_after": 1,
  "next_review_date": "2025-08-02",
  "learning_mode": false,
  "consecutive_familiar": 0,
  "next_interval_days": 1
}
```

---

## 7. 统计模块

### GET /api/stats/overview

获取学习统计概览。

**Headers:** `Authorization: Bearer <token>`

**Response (200):**

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "total_cards": 256,
    "total_decks": 5,
    "due_today": 18,
    "reviewed_today": 12,
    "learned_today": 3,
    "mastered_cards": 120,
    "learning_cards": 80,
    "stage_distribution": {
      "0": 20, "1": 28, "2": 25, "3": 22, "4": 20,
      "5": 18, "6": 16, "7": 15, "8": 12
    },
    "due_stage_distribution": {
      "0": 3, "1": 5, "2": 4, "3": 3, "4": 2,
      "5": 1, "6": 0, "7": 0, "8": 0
    }
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| mastered_cards | int | 已掌握卡片（Stage ≥ 5） |
| learning_cards | int | 学习中卡片（Stage 0-4） |
| stage_distribution | map<string,int> | 全部卡片阶段分布（0-8） |
| due_stage_distribution | map<string,int> | 今日到期卡片阶段分布（0-8） |

---

### GET /api/stats/deck/{deckId}

获取牌组级统计。

**Headers:** `Authorization: Bearer <token>`

**Response (200):**

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "deck_id": "uuid",
    "deck_name": "日语N5",
    "total_cards": 42,
    "due_today": 5,
    "reviewed_today": 3,
    "new_cards": 4,
    "learning_cards": 2,
    "mastered_cards": 18,
    "stage_distribution": {
      "0": 5,
      "1": 8,
      "2": 6,
      "3": 7,
      "4": 5,
      "5": 4,
      "6": 3,
      "7": 2,
      "8": 2
    },
    "due_stage_distribution": {
      "0": 1, "1": 2, "2": 1, "3": 1, "4": 0,
      "5": 0, "6": 0, "7": 0, "8": 0
    }
  }
}
```

---

### GET /api/stats/trend

获取复习趋势数据。

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| days | int | 30 | 最近多少天 |

**Response (200):**

```json
{
  "code": 200,
  "message": "success",
  "data": [
    {
      "date": "2025-07-02",
      "reviewed": 15,
      "learned": 5
    },
    {
      "date": "2025-07-03",
      "reviewed": 20,
      "learned": 3
    }
  ]
}
```

---

## 8. 数据管理模块

### POST /api/backup/export

导出当前用户的全量数据快照。

**Headers:** `Authorization: Bearer <token>`

**Response (200):**

```json
{
  "code": 200,
  "message": "备份已创建",
  "data": {
    "backup_id": "uuid",
    "exported_at": "2025-08-02T10:00:00Z",
    "data": {
      "user": { ... },
      "decks": [ ... ],
      "review_logs": [ ... ]
    }
  }
}
```

> 前端可将 `data` 字段保存为 JSON 文件供用户下载。

---

### POST /api/backup/import

导入数据快照（覆盖恢复）。先删除当前用户所有数据，再写入备份数据。

**Headers:** `Authorization: Bearer <token>`

**Request Body:**

```json
{
  "data": {
    "user": { ... },
    "decks": [ ... ],
    "review_logs": [ ... ]
  }
}
```

**Response (200):**

```json
{
  "code": 200,
  "message": "数据已恢复",
  "data": {
    "imported_decks": 5,
    "imported_cards": 256,
    "imported_review_logs": 1024
  }
}
```

> **警告：** 此操作不可逆，导入前会清除当前用户所有数据。