#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -x "./bootstrap/zig-out/bin/with" ]]; then
  echo "[gate-stage0] building bootstrap compiler"
  (cd bootstrap && zig build)
fi

echo "[gate-stage0] rebuilding stage2 from bootstrap"
./scripts/rebuild_selfhost.sh stage2

if [[ ! -x "./out/bin/with-stage2" ]]; then
  echo "[gate-stage0] missing out/bin/with-stage2 after rebuild" >&2
  exit 1
fi

echo "[gate-stage0] stage2 compiler produced successfully"
