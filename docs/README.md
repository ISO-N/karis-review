# Karis Review — 文档索引

## 领域词汇

- [领域词汇表](CONTEXT.md) — 领域术语与架构词汇（模块/深度/接缝/适配器/局部性），架构评审与代码设计共用；已收敛事实源清单与深化中的新模块术语

## 需求工程

- [用户需求](requirements/user-requirements.md) — 28 条用户需求 + 6 条非功能需求
- [系统需求](requirements/system-requirements.md) — 排期算法、数据模型、API 定义、非功能需求

## 软件设计

- [体系结构设计](design/architecture.md) — 分层架构、包结构、技术选型、模块依赖
- [数据库设计](design/database.md) — ERD、表结构、索引、Flyway 迁移、关键查询
- [接口设计](design/api.md) — REST API 完整定义，含请求/响应示例
- [测试说明](design/testing.md) — 部件测试、系统测试、运行命令与数据隔离
- [排期测试向量](design/scheduling-vectors.json) — 跨语言排期公式测试向量（语言无关单一事实源，后端 SchedulingVectorsTest 与前端 scheduling_vectors_test 同源断言）
- [前端设计说明](frontend-design.md) — 视觉规范（含暗色模式）、信息架构、动效规范（Motion Tokens）、组件规范与实现文件索引；交互原型见 [frontend-design/index.html](frontend-design/index.html)，Flutter 页面截图见 [手机版](frontend-design/screenshots/mobile/) 与 [平板版](frontend-design/screenshots/tablet/)

## 项目信息

| 项目 | 内容 |
|------|------|
| Android release 包名 | `top.kariscode.karisreview` |
| Android debug 包名 | `top.kariscode.karisreview.debug`（可与 release 共存） |
| 前端 | Flutter 3.x + Riverpod + GoRouter |
| 后端 | Spring Boot 3.x + Maven + Java 21 |
| 数据库 | PostgreSQL 16 |
| 生产 API | `https://review.kariscode.top/api` |