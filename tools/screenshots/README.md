# Karis Review 界面截图

使用 Playwright 驱动 Chrome，将 Flutter Web 的每个页面和关键组件分别截成手机、平板两张图。

## 前置条件

1. 启动后端：

```bash
docker compose up -d postgres
cd backend
mvn spring-boot:run
```

2. 启动 Flutter Web（release 构建）：

```bash
cd frontend
flutter build web --release --dart-define=API_BASE_URL=http://localhost:8080/api
python -m http.server 8082 --directory build/web
```

3. 安装截图工具依赖：

```bash
cd tools/screenshots
npm install
```

## 运行

```bash
cd tools/screenshots
node capture.cjs
```

脚本会自动注册两个临时账号并生成演示数据，输出到：

- `docs/frontend-design/screenshots/mobile/`
- `docs/frontend-design/screenshots/tablet/`

如果 `playwright-core` 没有安装在 `tools/screenshots/node_modules`，可通过环境变量指定安装位置：

```bash
PLAYWRIGHT_CORE_PATH=/path/to/node_modules/playwright-core node capture.cjs
```
