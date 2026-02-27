#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase4 await-lowering tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(await-run) $file"
  else
    echo "FAIL(await-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(await-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(await-run-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_pass "bootstrap/test/cases/async_basic.w"
expect_run_pass "bootstrap/test/cases/async_sync_bridge.w"
expect_run_pass "bootstrap/test/cases/async_multi.w"

cat >"$tmpdir/await_non_task_fail.w" <<'EOF1'
fn main -> i32:
    let x = 7
    let _y = x.await
EOF1
expect_run_fail "$tmpdir/await_non_task_fail.w"

cat >"$tmpdir/await_task_ok.w" <<'EOF2'
async fn plus(x: i32) -> i32:
    x + 2

fn main -> i32:
    let t = plus(40)
    let r = t.await
    if r == 42 then 0 else 1
EOF2
expect_run_pass "$tmpdir/await_task_ok.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase4 await-lowering tests: $failures failure(s)"
  exit 1
fi

echo "phase4 await-lowering tests: PASS"
