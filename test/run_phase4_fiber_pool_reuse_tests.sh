#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase4 fiber pool reuse tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(fiber-pool-run) $file"
  else
    echo "FAIL(fiber-pool-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(fiber-pool-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(fiber-pool-run-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_pass "test/cases/fiber_pool_reuse.w"
expect_run_pass "test/cases/async_basic.w"

cat >"$tmpdir/fiber_pool_reuses_arity_fail.w" <<'EOF1'
extern fn with_fiber_pool_reuses() -> i64

fn main -> i32:
    let _x = with_fiber_pool_reuses(1)
EOF1
expect_run_fail "$tmpdir/fiber_pool_reuses_arity_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase4 fiber pool reuse tests: $failures failure(s)"
  exit 1
fi

echo "phase4 fiber pool reuse tests: PASS"
