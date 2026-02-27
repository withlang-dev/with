#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase4 task-must-use tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_build_warn_msg() {
  local file="$1"
  local msg="$2"
  local stderr_file="$tmpdir/stderr.warn.$$"
  if "$WITH_BIN" build "$file" >/dev/null 2>"$stderr_file"; then
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(task-must-use-warn) $file"
    else
      echo "FAIL(task-must-use-warn-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  else
    echo "FAIL(task-must-use-build) $file"
    cat "$stderr_file"
    failures=$((failures + 1))
  fi
  rm -f "$stderr_file"
}

expect_build_pass_no_msg() {
  local file="$1"
  local forbidden="$2"
  local stderr_file="$tmpdir/stderr.build.$$"
  if "$WITH_BIN" build "$file" >/dev/null 2>"$stderr_file"; then
    if grep -Fq "$forbidden" "$stderr_file"; then
      echo "FAIL(task-must-use-unexpected-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    else
      echo "PASS(task-must-use-no-msg) $file"
    fi
  else
    echo "FAIL(task-must-use-build) $file"
    cat "$stderr_file"
    failures=$((failures + 1))
  fi
  rm -f "$stderr_file"
}

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.run.$$"; then
    echo "PASS(task-must-use-run) $file"
  else
    echo "FAIL(task-must-use-run) $file"
    cat "$tmpdir/stderr.run.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.run.$$"
}

cat >"$tmpdir/task_must_use_call_warn.w" <<'EOF1'
async fn work -> i32:
    1

fn main -> i32:
    work()
    0
EOF1
expect_build_warn_msg "$tmpdir/task_must_use_call_warn.w" "E0801: unused Task value"

cat >"$tmpdir/task_must_use_async_block_warn.w" <<'EOF2'
fn main -> i32:
    async: 1 + 2
    0
EOF2
expect_build_warn_msg "$tmpdir/task_must_use_async_block_warn.w" "E0801: unused Task value"

cat >"$tmpdir/task_must_use_await_ok.w" <<'EOF3'
async fn work -> i32:
    41 + 1

fn main -> i32:
    let t = work()
    let r = t.await
    if r == 42 then 0 else 1
EOF3
expect_run_pass "$tmpdir/task_must_use_await_ok.w"
expect_build_pass_no_msg "$tmpdir/task_must_use_await_ok.w" "E0801: unused Task value"

cat >"$tmpdir/task_must_use_spawn_ok.w" <<'EOF4'
async fn work -> i32:
    1

fn main -> i32:
    spawn work()
    0
EOF4
expect_run_pass "$tmpdir/task_must_use_spawn_ok.w"
expect_build_pass_no_msg "$tmpdir/task_must_use_spawn_ok.w" "E0801: unused Task value"

if [[ "$failures" -ne 0 ]]; then
  echo "phase4 task-must-use tests: $failures failure(s)"
  exit 1
fi

echo "phase4 task-must-use tests: PASS"
