#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$(cd ../.. && pwd)"
protoc \
  --plugin="protoc-gen-dart=${PWD}/tool/protoc-gen-dart.bat" \
  -I "${ROOT}/proto" \
  --dart_out="lib/shared/proto" \
  "${ROOT}/proto/karis_review.proto"
