# API 传输体积测量

用于对比 JSON、gzip、Protobuf 在主要 API 上的传输体积。

## 前置条件

- 后端已启动，`API_BASE_URL` 默认为 `http://localhost:8080/api`。
- 提供一个有效 JWT，可通过 `Authorization: Bearer <token>` 传入。

## 使用

```bash
TOKEN=... bash tools/payload-benchmark/measure.sh /sync/bootstrap
TOKEN=... bash tools/payload-benchmark/measure.sh /review/sessions
```

脚本输出响应字节数、gzip 后字节数和压缩率。

## 样例数据

`sample-bootstrap.json` 是 1000 张卡片的同步响应样例，用于在无后端时估算 JSON 体积：

```bash
python tools/payload-benchmark/compare-json.py
```

## 验收口径

- 无变化增量同步应接近零业务载荷。
- 大库样例中 Protobuf + gzip 应明显小于原 JSON。
