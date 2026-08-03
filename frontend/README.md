# Karis Review Flutter 客户端

Karis Review 的 Flutter 客户端，面向 Windows、Android、iOS。应用采用离线优先架构：首次登录后拉取全量快照到本地 Drift/SQLite，之后可离线浏览卡组、卡片、统计并继续评分；评分先写本地待同步队列，恢复网络后自动补传。

## 常用命令

```bash
flutter pub get
dart run build_runner build
flutter run -d windows
flutter build apk --release --dart-define=API_BASE_URL=https://review.kariscode.top/api
flutter build apk --debug --dart-define=API_BASE_URL=https://review.kariscode.top/api
flutter test
flutter analyze
```

Android release/debug 使用不同包名：`top.kariscode.karisreview` 与 `top.kariscode.karisreview.debug`，可同机共存。

## 离线能力边界

- 登录、注册、创建/编辑/删除、导入导出备份、修改设置仍需网络。
- 首次使用必须先联网完成 `/api/sync/bootstrap`。
- 离线评分使用 `client_request_id` 幂等，并携带 `review_version`；服务器冲突时默认按服务器状态刷新。
- 设置页提供“以服务器为准”的危险操作，用于丢弃全部待同步评分并重新拉取服务器数据。
