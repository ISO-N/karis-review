#!/usr/bin/env bash
set -euo pipefail

TOKEN="${TOKEN:?请设置 TOKEN}"
API_BASE_URL="${API_BASE_URL:-http://localhost:8080/api}"
PATH_SPEC="${1:?用法: measure.sh <path>}"
URL="${API_BASE_URL}${PATH_SPEC}"

raw_file="$(mktemp)"
gzip_file="$(mktemp)"

curl -sS \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Accept: application/json" \
  "${URL}" > "${raw_file}"

curl -sS \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Accept: application/json" \
  -H "Accept-Encoding: gzip" \
  --output "${gzip_file}" \
  --write-out '%{size_download}\n' \
  "${URL}" > "${gzip_file}.size"

raw_size="$(wc -c < "${raw_file}")"
gzip_size="$(cat "${gzip_file}.size")"

rm -f "${raw_file}" "${gzip_file}" "${gzip_file}.size"

printf 'raw bytes: %s\n' "${raw_size}"
printf 'gzip bytes: %s\n' "${gzip_size}"
printf 'reduction: %.1f%%\n' "$(awk -v a="${raw_size}" -v b="${gzip_size}" 'BEGIN { print (1 - b / a) * 100 }')"
