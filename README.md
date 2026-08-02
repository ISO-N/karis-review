# Karis Review

极简、专注的间隔重复闪卡复习应用。项目文档索引见 [docs/README.md](docs/README.md)。

## 技术栈

- 后端：Spring Boot 3.4 + Java 21 + Maven + Spring Data JPA + Flyway + Spring Security/JWT
- 前端：Flutter 3 + Riverpod + GoRouter + Dio + flutter_quill + flutter_math_fork + flutter_highlight
- 数据库：PostgreSQL 16

## 快速开始

### 1. 启动数据库

```bash
docker compose up -d postgres
```

### 2. 启动后端

```bash
cd backend
mvn spring-boot:run
```

后端默认运行在 `http://localhost:8080/api`。

### 3. 启动前端

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

生产构建：

```bash
cd frontend
flutter build web --release --dart-define=API_BASE_URL=https://review.kariscode.top/api
```

## CI 与镜像发布

GitHub Actions 会在 PR 和 `main` 分支自动运行：

- 后端：`./mvnw test`（CI 使用 PostgreSQL 16 服务）
- 前端：`flutter analyze`、`flutter test`

合并到 `main` 后，CI 会把后端构建并发布到 GitHub Packages：

```text
ghcr.io/iso-n/karis-review-backend:latest
ghcr.io/iso-n/karis-review-backend:sha-<commit-sha>
```

GitHub Packages 中该包最多保留最新两个镜像，旧版本由 CI 自动删除；清理逻辑会保留仍被 tag 引用的多架构子清单，避免 `latest` 指向缺失清单。

## 生产部署

生产环境通过 [docker-compose.prod.yaml](docker-compose.prod.yaml) 启动后端 API 与 PostgreSQL：

```bash
cp .env.prod.example .env.prod
# 编辑 .env.prod：POSTGRES_PASSWORD、JWT_SECRET；私有镜像再填 GHCR_USERNAME、GHCR_TOKEN
./deploy.sh
```

`deploy.sh` 会拉取最新镜像、创建或更新容器并清理本地悬空镜像。后端默认监听 `http://<服务器地址>:8080/api`。

## 功能

- 邮箱注册、登录、退出
- 牌组与卡片管理
- 富文本卡片编辑（粗体、斜体、列表、标题、LaTeX、代码高亮）
- 学习模式与复习模式，基于 Stage 0-8 的间隔重复算法
- FORGET / VAGUE / FAMILIAR 评分与 2^n 重学队列插入
- 学习统计概览、牌组进度、复习趋势
- JSON 数据备份导出与覆盖恢复
- 每日定时应用级备份与用户自定义刷新时间

## 测试

```bash
cd backend
mvn test

cd frontend
flutter test
```
