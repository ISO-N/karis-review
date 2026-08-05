# ADR-008: JWT 多密钥轮换（kid）

## Status
已接受（阶段一落地）

## Context
原 JWT_SECRET 单密钥无轮换机制（G9），密钥泄露时无法平滑更换，会强制全员重新登录。

## Decision
引入密钥标识（kid）：签发使用 jwt.active-kid 指定的密钥并在 Token header 携带 kid；
验签时按 kid 匹配密钥，未知 kid 回退逐个密钥尝试（兼容滚动期旧 Token）。
配置：`jwt.keys=k1=secret1,k2=secret2`（逗号分隔），未配置时回退 jwt.secret 单密钥（kid=legacy）。

## Consequences
- 更容易：轮换 = 新增新密钥 → 切换 active-kid → 移旧密钥，全程用户无感
- 更难：密钥管理从单值变为列表；需要配置编排（环境变量）
