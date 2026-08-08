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

### 1.5 传输与缓存约定

- 服务端默认启用 gzip 压缩，覆盖 JSON 与 `application/x-protobuf` 响应。
- `/api/decks`、`/api/stats/overview`、`/api/stats/deck/{deckId}` 返回私有 ETag；客户端携带 `If-None-Match` 时未变化响应为 304。
- 高流量接口支持同 URL 内容协商：默认 JSON，客户端携带 `Accept: application/x-protobuf` 时返回 Protobuf；POST 请求同步携带 `Content-Type: application/x-protobuf`。
- 高流量 Protobuf 接口包括：同步 Bootstrap、复习会话创建/分页、复习队列、评分同步。错误响应在 Protobuf 路径返回 `ApiError`。

### 1.6 分页

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

### GET /api/auth/config

获取注册公开配置，用于前端决定是否显示邀请码输入框。

**Response (200):**

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "invite_code_required": false
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| invite_code_required | boolean | 注册是否必须填写邀请码 |

---

### POST /api/auth/register

注册新用户（需先通过 `POST /api/auth/register-code` 获取邮箱验证码）。

**Request Body:**

```json
{
  "email": "user@example.com",
  "password": "securePassword123",
  "verification_code": "123456",
  "invite_code": "可选邀请码"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| email | string | 是 | 邮箱地址 |
| password | string | 是 | 密码（6-128 位） |
| verification_code | string | 是 | 邮箱验证码（6 位数字，15 分钟有效） |
| invite_code | string | 启用邀请码时必填 | 注册邀请码；未启用时忽略 |

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

**错误码：** 400（邮箱已注册/邮箱格式无效/密码太短/请输入邀请码/邀请码无效/验证码错误/验证码已过期/验证码尝试次数过多）

---

### POST /api/auth/register-code

发送注册邮箱验证码。邮箱已注册时返回 400。

**Request Body:**

```json
{
  "email": "user@example.com"
}
```

**Response (200):**

```json
{
  "code": 200,
  "message": "验证码已发送",
  "data": null
}
```

**错误码：** 400（邮箱已注册）、429（60 秒内重复请求）

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

### PUT /api/auth/password

修改密码（需登录）。

**Headers:** `Authorization: Bearer <token>`

**Request Body:**

```json
{
  "current_password": "oldPassword123",
  "new_password": "newPassword123"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| current_password | string | 是 | 当前密码 |
| new_password | string | 是 | 新密码（6-128 位） |

**Response (200):**

```json
{
  "code": 200,
  "message": "密码已修改",
  "data": null
}
```

**说明：** 修改成功后服务端不强制吊销已有 Token，前端主动登出并回登录页。

**错误码：** 400（当前密码错误/新密码格式无效）

---

### POST /api/auth/password/reset-code

发送找回密码验证码。邮箱不存在时也返回成功（防枚举）。

**Request Body:**

```json
{
  "email": "user@example.com"
}
```

**Response (200):**

```json
{
  "code": 200,
  "message": "验证码已发送",
  "data": null
}
```

**错误码：** 429（60 秒内重复请求）

---

### POST /api/auth/password/reset

用验证码重置密码（未登录场景）。

**Request Body:**

```json
{
  "email": "user@example.com",
  "code": "123456",
  "new_password": "newPassword123"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| email | string | 是 | 邮箱地址 |
| code | string | 是 | 验证码（6 位数字，15 分钟有效） |
| new_password | string | 是 | 新密码（6-128 位） |

**Response (200):**

```json
{
  "code": 200,
  "message": "密码已重置",
  "data": null
}
```

**错误码：** 400（验证码错误/验证码已过期/验证码尝试次数过多）

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

### GET /api/logs

获取当前用户的操作日志（脱敏后）。

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| page | int | 0 | 页码（从 0 开始） |
| size | int | 50 | 每页条数，服务端限制在 1-100 |
| level | string | 空 | 按日志级别过滤，如 INFO/WARN/ERROR |
| category | string | 空 | 按日志分类过滤，如 AUTH/REVIEW/SYNC |

**Response (200):**

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "content": [
      {
        "id": "uuid",
        "level": "INFO",
        "category": "AUTH",
        "message": "Registration successful",
        "details": null,
        "created_at": "2025-08-02T12:00:00Z"
      }
    ],
    "page": 0,
    "size": 50,
    "total_elements": 1,
    "total_pages": 1
  }
}
```

---

## 4. 卡组模块

### GET /api/decks

获取当前用户所有卡组列表。

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
      "stage_distribution": [5, 8, 6, 7, 5, 4, 3, 2, 2],
      "due_stage_distribution": [1, 2, 1, 1, 0, 0, 0, 0, 0],
      "created_at": "2025-07-01T10:00:00Z"
    }
  ]
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| card_count | int | 卡组内卡片总数 |
| due_count | int | 今日待复习卡片数 |
| new_count | int | 可学习的新卡数（Stage 0 且非重学） |
| mastered_count | int | 已掌握卡片数（Stage ≥ 5） |
| stage_distribution | array<int> | 各阶段卡片数量分布（0-8） |
| due_stage_distribution | array<int> | 今日到期卡片阶段分布（0-8），仅统计已排期（next_review_date 非空且 ≤ 今日）的卡，不含未学新卡 |

---

### POST /api/decks

创建新卡组。

**Request Body:**

```json
{
  "name": "日语N5"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | string | 是 | 卡组名称（1-100 字符） |

**Response (200):**

```json
{
  "code": 200,
  "message": "卡组已创建",
  "data": {
    "id": "uuid",
    "name": "日语N5",
    "card_count": 0,
    "due_count": 0,
    "new_count": 0,
    "mastered_count": 0,
    "stage_distribution": [0, 0, 0, 0, 0, 0, 0, 0, 0],
    "due_stage_distribution": [0, 0, 0, 0, 0, 0, 0, 0, 0],
    "created_at": "2025-08-01T10:00:00Z"
  }
}
```

---

### PUT /api/decks/{deckId}

重命名卡组。

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
  "message": "卡组已更新",
  "data": {
    "id": "uuid",
    "name": "日语N5-改",
    "card_count": 42,
    "due_count": 5,
    "new_count": 3,
    "mastered_count": 20,
    "stage_distribution": [5, 8, 6, 7, 5, 4, 3, 2, 2],
    "due_stage_distribution": [1, 2, 1, 1, 0, 0, 0, 0, 0],
    "created_at": "2025-07-01T10:00:00Z"
  }
}
```

---

### DELETE /api/decks/{deckId}

删除卡组（级联删除卡组内所有卡片及复习记录）。

**Headers:** `Authorization: Bearer <token>`

**Response (200):**

```json
{
  "code": 200,
  "message": "卡组已删除",
  "data": null
}
```

**错误码：** 404（卡组不存在或不属于当前用户）

---

## 5. 卡片模块

### GET /api/decks/{deckId}/cards

获取卡组内所有卡片列表。

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| page | int | 0 | 页码 |
| size | int | 20 | 每页条数 |
| filter | string | all | 卡片筛选：`all`、`new`、`due`、`learning`；`new` 返回 Stage 0 且非重学的卡片，按创建时间倒序 |
| q | string | 空 | 按正面/反面不区分大小写搜索；与 `filter` 叠加，`%`、`_`、`\` 按字面值匹配，最长 100 字符 |

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

### POST /api/cards/batch-delete

批量删除当前用户的多张卡片。

**Headers:** `Authorization: Bearer <token>`

**Request Body:**

```json
{
  "card_ids": ["uuid-1", "uuid-2"]
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| card_ids | array | 是 | 非空卡片 ID 列表，最多 1000 个 |

**Response (200):**

```json
{
  "code": 200,
  "message": "卡片已删除",
  "data": {
    "deleted_cards": 2
  }
}
```

> 只删除当前用户仍存在的卡片；已不存在或不属于当前用户的 ID 忽略，返回实际删除数。

### POST /api/decks/{deckId}/cards/import/preview

解析用户粘贴或上传的卡片 JSON 数组，返回逐行规范化预览。

**Headers:** `Authorization: Bearer <token>`

**Request Body:**

```json
{
  "content": "[{\"front\":\"正面\",\"back\":\"反面\"}]"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| content | string | 是 | 原始 JSON 数组文本，最大 2MB |

**Response (200):**

```json
{
  "code": 200,
  "message": "解析完成",
  "data": {
    "total": 2,
    "valid_count": 2,
    "invalid_count": 0,
    "cards": [
      {
        "index": 0,
        "front": "正面",
        "back": "反面",
        "valid": true,
        "message": null
      }
    ]
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| total | int | 解析出的行数 |
| valid_count | int | 有效卡片数 |
| invalid_count | int | 无效卡片数 |
| cards | array | 逐行预览，`valid=false` 时 `message` 为中文错误信息 |

格式规则：

- 顶层必须是 JSON 数组，元素为 `{"front":"...","back":"..."}`。
- `front`、`back` 必须是非空字符串，未知字段忽略。
- 单个元素无效不会中断解析；顶层非数组、空数组、超过 1000 行或超过 2MB 时返回 400。
- 预览接口不保存任何状态。

---

### POST /api/decks/{deckId}/cards/import

将预览后的卡片批量导入当前卡组。

**Headers:** `Authorization: Bearer <token>`

**Request Body:**

```json
{
  "cards": [
    {
      "front": "正面",
      "back": "反面"
    }
  ]
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| cards | array | 是 | 非空卡片列表，最多 1000 张 |

**Response (200):**

```json
{
  "code": 200,
  "message": "卡片已导入",
  "data": {
    "imported_cards": 2,
    "imported_card_ids": ["uuid-1", "uuid-2"]
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| imported_cards | int | 本次导入卡片数 |
| imported_card_ids | array | 本次导入卡片 ID，供前端实现“撤销导入”（前端先弹确认对话框，再调用批量删除） |

> 导入接口会重新校验卡组归属和每行内容；有任何无效行则整体拒绝，不做部分导入。导入的卡片均为 Stage 0 新卡，不包含排期状态与复习日志。

---

## 6. 复习模块

### GET /api/review/due

获取今日待复习卡片列表。

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| deck_id | UUID | null | 可选，按卡组筛选 |
| limit | int | 500 | 最大返回量 |
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
      "reentry_stage": null,
      "next_review_date": "2025-08-02",
      "learning_step": 0,
      "review_version": 0,
      "learning_origin": null
    }
  ]
}
```

> 复习队列中**处于重学模式**的卡片（复习阶段 FORGET/VAGUE 后以 2^n 间距插入的卡片，`learning_origin` 为 `REVIEW`）也会出现在此列表中。
> 前端根据 `stage`、`learning_mode`、`consecutive_familiar`、`reentry_stage` 本地推导 `learning_goal` 与熟悉/模糊/当前间隔，接口不再重复传输这些字段。

---

### GET /api/review/new

获取学新队列：全部待学习新卡（Stage 0 且未进入学习模式）+ 学新阶段忘记后进入重学的卡片（`learning_origin` 为 `NEW`，按 2^n 间距插入）。

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| deck_id | UUID | null | 可选，按卡组筛选 |
| limit | int | 10 | 最大返回量 |
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
      "reentry_stage": null,
      "next_review_date": null,
      "learning_step": 0,
      "review_version": 0,
      "learning_origin": null
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
    "new_cards": 20,
    "learning_cards": 80,
    "stage_distribution": [20, 28, 25, 22, 20, 18, 16, 15, 12],
    "due_stage_distribution": [3, 5, 4, 3, 2, 1, 0, 0, 0],
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| due_today | int | 今日待复习卡片数 |
| reviewed_today | int | 今日复习数（不含新学，重学计入） |
| learned_today | int | 今日新学数（新卡 FAMILIAR） |
| mastered_cards | int | 已掌握卡片（Stage ≥ 5） |
| new_cards | int | 可学习的新卡数 |
| learning_cards | int | 学习中卡片（Stage 0-4） |
| stage_distribution | array<int> | 全部卡片阶段分布（0-8） |
| due_stage_distribution | array<int> | 今日到期卡片阶段分布（0-8），仅统计已排期（next_review_date 非空且 ≤ 今日）的卡，不含未学新卡 |

---

### GET /api/stats/deck/{deckId}

获取卡组级统计。

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
    "stage_distribution": [5, 8, 6, 7, 5, 4, 3, 2, 2],
    "due_stage_distribution": [1, 2, 1, 1, 0, 0, 0, 0, 0],
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| deck_id | string | 卡组 ID |
| deck_name | string | 卡组名称 |
| total_cards | int | 卡组卡片总数 |
| due_today | int | 今日待复习卡片数 |
| reviewed_today | int | 今日复习数（不含新学，重学计入） |
| new_cards | int | 可学习的新卡数 |
| learning_cards | int | 重学中的卡片数 |
| mastered_cards | int | 已掌握卡片数 |
| stage_distribution | array<int> | 各阶段卡片数量分布（0-8） |
| due_stage_distribution | array<int> | 今日到期卡片阶段分布（0-8），仅统计已排期（next_review_date 非空且 ≤ 今日）的卡，不含未学新卡 |

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

> `reviewed` 不含新学操作；`learned` 统计新卡上的 FAMILIAR。

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

---

## 9. 离线同步与动态复习会话

### POST /api/review/sessions

创建复习队列快照，首次返回一页卡片。`mode=new` 时队列为学新队列（待学新卡 + `learning_origin=NEW` 的重学卡）；`mode=due` 时为复习队列（到期卡 + `learning_origin=REVIEW`/null 的重学卡）。卡片字段含 `learning_origin`。

**Request Body:**

```json
{
  "mode": "due",
  "deck_id": null,
  "batch_size": 10
}
```

**Response (200):**

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "session_id": "uuid",
    "mode": "due",
    "deck_id": null,
    "batch_size": 10,
    "total": 37,
    "cursor": 10,
    "has_more": true,
    "cards": [ ... ]
  }
}
```

### GET /api/review/sessions/{sessionId}

按 `cursor` 拉取下一页，默认 `limit=10`；会话过期返回 410。

### DELETE /api/review/sessions/{sessionId}

用户完成或离开复习时关闭会话。

### POST /api/review/sync

按顺序提交离线评分，每条使用 `client_request_id` 幂等，并用 `review_version` 校验服务器卡片状态。

**Request Body:**

```json
{
  "items": [
    {
      "client_request_id": "uuid",
      "card_id": "uuid",
      "rating": "FAMILIAR",
      "rated_at": "2025-08-02T12:00:00Z",
      "review_version": 3
    }
  ]
}
```

**Response 条目状态：** `SYNCED`、`ALREADY_SYNCED`、`CONFLICT`、`CARD_NOT_FOUND`。成功条目只返回 `client_request_id` 与 `status`；冲突条目额外返回 `current_card` 与最新 `review_version`。

### GET /api/sync/bootstrap

返回当前用户离线同步数据。无 `event_cursor` 或 `event_cursor=0` 时返回全量快照；携带上次事件游标时返回增量。

**Query Parameters:**

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| event_cursor | long | 0 | 上次同步返回的 `event_cursor`；0 表示全量 Bootstrap |

**Response 字段：**

| 字段 | 类型 | 说明 |
|------|------|------|
| server_time | string | 服务端 UTC 时间 |
| user | object | 用户邮箱与刷新时间 |
| decks | array | 全量时为卡组嵌套卡片；增量时为变更卡组 |
| changed_cards | array | 增量时发生创建/更新的卡片 |
| review_logs | array | 全量时全部日志；增量时新增日志；离线评分日志包含 `client_request_id` |
| deleted_deck_ids | array | 增量时被删除的卡组 ID |
| deleted_card_ids | array | 增量时被删除的卡片 ID |
| deleted_review_log_ids | array | 增量时被删除的复习日志 ID |
| event_cursor | long | 本次已处理到的事件游标，客户端应保存并用于下次请求 |
| has_more | bool | 是否还有后续事件页 |
| reset_required | bool | 服务端事件已清理或游标不可用时要求客户端重新全量同步 |

该接口支持 `Accept: application/x-protobuf`；Protobuf 路径直接返回 `SyncResponse`，JSON 路径保持统一包装。

- 所有复习队列和卡片响应都返回 `review_version`。
- `review_logs` 会回传 `client_request_id`，客户端用它替换本地待同步镜像，避免同一评分被重复统计。
- 单卡评分请求可携带 `client_request_id` 与 `review_version`；版本不一致返回 409。
- 两个设备同时评分时，服务端用事务行锁串行处理，后提交方因版本不一致被拒绝。