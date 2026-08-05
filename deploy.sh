#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${ENV_FILE:-.env.prod}"
PROFILE="${1:-}"   # 可选：replica（启用只读副本）

if [[ ! -f "$ENV_FILE" ]]; then
  echo "缺少 $ENV_FILE，请先根据 .env.prod.example 创建并填写配置。" >&2
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

if [[ -n "${GHCR_USERNAME:-}" || -n "${GHCR_TOKEN:-}" ]]; then
  if [[ -z "${GHCR_USERNAME:-}" || -z "${GHCR_TOKEN:-}" ]]; then
    echo "配置 GHCR 凭据时，GHCR_USERNAME 和 GHCR_TOKEN 必须同时填写。" >&2
    exit 1
  fi
  echo "登录 GHCR..."
  printf '%s' "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USERNAME" --password-stdin
fi

COMPOSE_ARGS=(--env-file "$ENV_FILE" -f docker-compose.prod.yaml)
if [[ "$PROFILE" == "replica" ]]; then
  COMPOSE_ARGS+=(--profile replica)
  echo "启用只读副本（读扩展）..."
fi

# 拉取镜像（MinIO/Grafana/Loki 等基础设施镜像首次部署时拉取）
docker compose "${COMPOSE_ARGS[@]}" pull

# 创建 MinIO 备份桶（幂等）
echo "确保 MinIO 备份桶存在..."
docker compose "${COMPOSE_ARGS[@]}" up -d minio
sleep 5
MINIO_BUCKET="${BACKUP_S3_BUCKET:-karis-review-backups}"
docker compose "${COMPOSE_ARGS[@]}" exec -T minio sh -c \
  "mc alias set local http://localhost:9000 \$(printenv MINIO_ROOT_USER) \$(printenv MINIO_ROOT_PASSWORD) 2>/dev/null; \
   mc mb --ignore-existing local/$MINIO_BUCKET" || echo "警告：MinIO 桶创建失败（若使用外部对象存储可忽略）"

# 启动全部服务
docker compose "${COMPOSE_ARGS[@]}" up -d --remove-orphans

echo "部署完成。服务状态："
docker compose "${COMPOSE_ARGS[@]}" ps

docker image prune -f || true

echo ""
echo "访问入口："
echo "  API       https://review.kariscode.top/api"
echo "  Web       https://review.kariscode.top"
echo "  Grafana   http://127.0.0.1:${GRAFANA_PORT:-3000}  (admin / 配置的 GRAFANA_ADMIN_PASSWORD)"
echo "  Prometheus http://127.0.0.1:${PROMETHEUS_PORT:-9090}"
echo "  MinIO     http://127.0.0.1:${MINIO_CONSOLE_PORT:-9001}"
