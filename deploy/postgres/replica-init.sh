#!/bin/bash
# PostgreSQL 只读副本初始化：从主库 pg_basebackup 克隆（流复制）
# 挂载为 docker-entrypoint-initdb.d/00-replica-init.sh，仅当数据目录为空时执行。
set -euo pipefail

if [ -s "$PGDATA/PG_VERSION" ]; then
  echo "replica data dir already initialized, skipping"
  exit 0
fi

echo "Waiting for primary to accept connections..."
until pg_isready -h "$PRIMARY_HOST" -p "${PRIMARY_PORT:-5432}" -U "$POSTGRES_USER"; do
  sleep 2
done

# 创建复制账号（在主库上执行一次）
PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$PRIMARY_HOST" -p "${PRIMARY_PORT:-5432}" -U "$POSTGRES_USER" -d postgres <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${REPLICA_USER}') THEN
    CREATE ROLE ${REPLICA_USER} REPLICATION LOGIN PASSWORD '${REPLICA_PASSWORD}';
  END IF;
END
\$\$;
SQL

# 清空数据目录（entrypoint 可能已初始化空目录）
rm -rf "$PGDATA"/*
rm -rf "$PGDATA"/.* 2>/dev/null || true

# 从主库全量克隆
PGPASSWORD="$REPLICA_PASSWORD" pg_basebackup \
  -h "$PRIMARY_HOST" -p "${PRIMARY_PORT:-5432}" \
  -U "$REPLICA_USER" \
  -D "$PGDATA" \
  -Fp -Xs -R \
  -S "replica_slot" \
  --checkpoint=fast

# pg_basebackup -R 已写入 standby.signal 与 primary_conninfo
echo "Replica initialized from primary"
