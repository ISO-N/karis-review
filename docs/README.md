# Karis Review — 文档索引

## 需求工程

- [用户需求](requirements/user-requirements.md) — 26 条用户需求 + 6 条非功能需求
- [系统需求](requirements/system-requirements.md) — 排期算法、数据模型、API 定义、非功能需求

## 软件设计

- [体系结构设计](design/architecture.md) — 分层架构、包结构、技术选型、模块依赖
- [数据库设计](design/database.md) — ERD、表结构、索引、Flyway 迁移、关键查询
- [接口设计](design/api.md) — REST API 完整定义，含请求/响应示例
- [前端设计说明](frontend-design.md) — 视觉规范、信息架构、动效与响应式方案；交互原型见 [frontend-design/index.html](frontend-design/index.html)

## 项目信息

| 项目 | 内容 |
|------|------|
| 包名 | `top.kariscode.karisreview` |
| 前端 | Flutter 3.x + Riverpod + GoRouter |
| 后端 | Spring Boot 3.x + Maven + Java 21 |
| 数据库 | PostgreSQL 16 |
| 生产 API | `https://review.kariscode.top/api` |