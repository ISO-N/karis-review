#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${ENV_FILE:-.env.prod}"

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

docker compose --env-file "$ENV_FILE" -f docker-compose.prod.yaml pull
docker compose --env-file "$ENV_FILE" -f docker-compose.prod.yaml up -d --remove-orphans
docker image prune -f
