## Problem Statement

前后端 API 交互存在明显传输浪费：

- 登录恢复、首页、牌组页、统计页、卡片页都会触发全量 `/sync/bootstrap`，首页一次进入会并发触发两次全量下载。
- Bootstrap 每次下载全部牌组、全部卡片、全部历史复习日志。
- 复习响应携带可由 `stage` 与学习状态推导的间隔字段，JSON 字段名和全零分布对象反复传输。
- 服务端未开启 HTTP 压缩，也没有条件请求缓存。
- 每次离线评分后立即单独调用 `/review/sync`，请求次数多，响应为每个成功条目返回完整评分结果。
- 线上接口只有 JSON，富文本字符串在弱网下体积偏大。

## Solution

- 开启服务端 gzip 压缩，覆盖 JSON 与 `application/x-protobuf`。
- 为牌组列表、概览统计、牌组统计增加私有 ETag/304。
- 高流量接口使用同 URL Protobuf 内容协商：同步 Bootstrap、复习会话创建/分页、复习队列、评分同步；默认 JSON，客户端生产请求优先 Protobuf。
- 新增 `sync_events` 表和数据库触发器，为牌组、卡片、复习日志、用户设置记录单调事件游标。
- `/api/sync/bootstrap` 支持 `event_cursor` 增量同步，返回变更实体、新增日志、删除 ID、`has_more`、`reset_required`。
- 前端保存事件游标，增量应用 upsert/delete，保留待同步日志；`SyncService` 单飞行/冷却刷新。
- 评分同步改为防抖批量提交，单飞行避免重叠请求。
- 精简 JSON/Protobuf 载荷：复习间隔与 `learning_goal` 由前端推导，阶段分布改为定长数组，成功同步条目不再返回完整评分结果。

## Commits

每个提交都保持代码和测试可运行。

1. 添加传输体积基线测量脚本与样例数据。
2. 开启服务端 gzip 压缩并增加验证测试。
3. 实现 ETag/304 与客户端 `If-None-Match` 复用。
4. 清理 JSON 响应冗余字段，阶段分布改数组。
5. 添加根级 Protobuf schema、后端代码生成、前端依赖和生成文件。
6. 实现 Protobuf 内容协商、错误响应和 JSON 回退。
7. 将 `/sync/bootstrap` 接入 Protobuf。
8. 将复习会话、复习队列、复习分页接入 Protobuf。
9. 将评分同步接入 Protobuf 并精简成功条目响应。
10. 新增 `sync_events` 迁移、触发器和事件查询。
11. 后端实现增量同步服务与游标/reset 逻辑。
12. 前端实现事件游标、增量应用、删除处理。
13. 重构 `SyncService` 单飞行/冷却刷新并改造调用方。
14. 增加评分批量防抖协调器。
15. 更新 API、数据库、架构、测试文档并完成回归。

## Decision Document

- 二进制格式采用 Protobuf，不采用 MessagePack 或 CBOR。
- 二进制只覆盖高流量同步/复习接口；CRUD、统计、备份、导入保留 JSON。
- 采用同 URL 内容协商，不新增 `/v2` 路径；默认 JSON，Protobuf 失败时回退 JSON。
- 增量删除采用 `sync_events` 事件表和触发器，不使用 `deleted_at` 列或当前 ID 全集。
- 游标使用单调整数 `event_seq`，不依赖时间戳。
- 事件表暂不自动清理，但协议包含 `reset_required`。
- 服务端压缩、ETag/304 与客户端单飞行/防抖同时实施。
- 前端 Protobuf 生成文件提交到仓库，后端由 Maven 构建生成。

## Testing Decisions

测试验证外部行为：请求体积、请求次数、响应内容、游标推进、删除结果、协议兼容和端到端功能。

- 后端沿用 Controller/Service 部件测试和真实 PostgreSQL 系统测试。
- 新增增量同步、Protobuf 内容协商、gzip、ETag/304 系统测试。
- 前端新增离线增量应用、删除处理、事件游标、单飞行刷新测试。
- 回归命令：`mvn test`、`flutter analyze`、`flutter test`。
- 验收标准：重复进入首页不触发全量 Bootstrap；无变化增量响应不含卡片/日志正文；大库样例上 Protobuf+gzip 相对原 JSON 明显下降。

## Out of Scope

- Redis、CDN、HTTP/3/QUIC。
- 复习会话服务端不再预写完整 `review_queue_items` 的存储优化。
- 备份导出/导入的二进制协议。
- 卡片富文本存储格式重构。
- 跨设备冲突策略完整产品化。
- 事件表自动清理任务。
