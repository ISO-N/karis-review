# ADR-006: 邮件投递异步化（Outbox 模式）

## Status
已接受（阶段一落地，V13 迁移 + MailOutboxHandler）

## Context
原 SmtpMailSender 在请求线程内同步发送，SMTP 故障直接导致注册/找回密码接口失败，
且验证码场景拖慢响应（G4）。

## Decision
验证码/重置邮件写入 outbox_events（与业务同事务提交），由 OutboxRelay 轮询投递，
失败指数退避重试（最多 10 次），超限进入 DEAD 死信保留 30 天。

## Consequences
- 更容易：接口响应不依赖 SMTP；失败可重试、可排查
- 更难：邮件存在数秒延迟（可接受）；死信需要人工关注（告警）
