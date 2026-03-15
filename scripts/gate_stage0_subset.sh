#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# selfhost seed — validate that a seed compiler can build stage2
SEED_BIN="${ROOT_DIR}/src/main"

if [[ ! -x "$SEED_BIN" ]]; then
  SEED_BIN="$(command -v with 2>/dev/null || true)"
fi

if [[ -z "$SEED_BIN" || ! -x "$SEED_BIN" ]]; then
  echo "[gate-stage0] error: no seed compiler — run 'make seed' or add with to PATH" >&2
  exit 1
fi

echo "[gate-stage0] rebuilding stage2 from selfhost seed"
./scripts/rebuild_selfhost.sh stage2

if [[ ! -x "./out/bin/with-stage2" ]]; then
  echo "[gate-stage0] missing out/bin/with-stage2 after rebuild" >&2
  exit 1
fi

echo "[gate-stage0] stage2 compiler produced successfully"
