#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase4 fiber context-switch tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_cmd_pass() {
  local label="$1"
  local cmd="$2"
  if bash -lc "$cmd" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(${label})"
  else
    echo "FAIL(${label})"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(fiber-run) $file"
  else
    echo "FAIL(fiber-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_cmd_pass "fiber-switch-symbol" "nm -g zig-out/bin/runtime/fiber_asm.o | rg -q \"_with_fiber_switch\""

expect_run_pass "bootstrap/test/cases/async_basic.w"
expect_run_pass "bootstrap/test/cases/async_multi.w"
expect_run_pass "bootstrap/test/cases/async_pipeline.w"
expect_run_pass "bootstrap/test/cases/select_await.w"
expect_run_pass "bootstrap/test/cases/select_await_three.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase4 fiber context-switch tests: $failures failure(s)"
  exit 1
fi

echo "phase4 fiber context-switch tests: PASS"
