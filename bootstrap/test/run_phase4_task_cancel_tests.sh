#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase4 task-cancel tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(task-cancel-run) $file"
  else
    echo "FAIL(task-cancel-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_fail_msg() {
  local file="$1"
  local msg="$2"
  local stderr_file="$tmpdir/stderr.err.$$"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$stderr_file"; then
    echo "FAIL(task-cancel-check-fail) $file"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(task-cancel-check-fail) $file"
    else
      echo "FAIL(task-cancel-check-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$stderr_file"
}

expect_run_pass "bootstrap/test/cases/task_cancel.w"
expect_run_pass "bootstrap/test/cases/p4_task_cancel.w"

cat >"$tmpdir/task_cancel_next_await.w" <<'EOF1'
async fn tick -> i32:
    0

async fn worker -> i32:
    let t1 = tick()
    let _ = t1.await
    let t2 = tick()
    let _ = t2.await
    99

fn main -> i32:
    let t = worker()
    t.cancel()
    let r = t.await
    if r == -1 then 0 else 1
EOF1
expect_run_pass "$tmpdir/task_cancel_next_await.w"

cat >"$tmpdir/task_cancel_non_task_fail.w" <<'EOF2'
fn main -> i32:
    let x = 7
    x.cancel()
    0
EOF2
expect_check_fail_msg "$tmpdir/task_cancel_non_task_fail.w" "cancel() requires a Task value"

if [[ "$failures" -ne 0 ]]; then
  echo "phase4 task-cancel tests: $failures failure(s)"
  exit 1
fi

echo "phase4 task-cancel tests: PASS"
