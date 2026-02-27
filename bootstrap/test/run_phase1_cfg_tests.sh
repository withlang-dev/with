#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase1 cfg tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

if zig test bootstrap/BorrowCfg.zig >/dev/null; then
  echo "PASS(cfg-unit-tests)"
else
  echo "FAIL(cfg-unit-tests)"
  failures=$((failures + 1))
fi

cat >"$tmpdir/cfg_semantics_ok.w" <<'EOF1'
fn main -> i32:
    var i = 0
    if i == 0 then
        i = i + 1
    while i < 3:
        i = i + 1
    i
EOF1
if "$WITH_BIN" check "$tmpdir/cfg_semantics_ok.w" >/dev/null 2>/dev/null; then
  echo "PASS(cfg-integration-check)"
else
  echo "FAIL(cfg-integration-check)"
  failures=$((failures + 1))
fi

cat >"$tmpdir/cfg_parse_fail.w" <<'EOF2'
fn main -> i32:
    if true then
EOF2
if "$WITH_BIN" check "$tmpdir/cfg_parse_fail.w" >/dev/null 2>/dev/null; then
  echo "FAIL(cfg-negative-parse)"
  failures=$((failures + 1))
else
  echo "PASS(cfg-negative-parse)"
fi

if [[ "$failures" -ne 0 ]]; then
  echo "phase1 cfg tests: $failures failure(s)"
  exit 1
fi

echo "phase1 cfg tests: PASS"
