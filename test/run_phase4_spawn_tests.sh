#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase4 spawn tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(spawn-run) $file"
  else
    echo "FAIL(spawn-run) $file"
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
    echo "FAIL(spawn-check-fail) $file"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(spawn-check-fail) $file"
    else
      echo "FAIL(spawn-check-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$stderr_file"
}

expect_build_pass_no_msg() {
  local file="$1"
  local forbidden="$2"
  local stderr_file="$tmpdir/stderr.build.$$"
  if "$WITH_BIN" build "$file" >/dev/null 2>"$stderr_file"; then
    if grep -Fq "$forbidden" "$stderr_file"; then
      echo "FAIL(spawn-build-unexpected-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    else
      echo "PASS(spawn-build-no-msg) $file"
    fi
  else
    echo "FAIL(spawn-build) $file"
    cat "$stderr_file"
    failures=$((failures + 1))
  fi
  rm -f "$stderr_file"
}

cat >"$tmpdir/spawn_async_fn_ok.w" <<'EOF1'
async fn work(x: i32) -> i32 =
    x + 1

fn main() -> i32 =
    spawn work(1)
    spawn work(2)
    0
EOF1
expect_run_pass "$tmpdir/spawn_async_fn_ok.w"
expect_build_pass_no_msg "$tmpdir/spawn_async_fn_ok.w" "E0801: unused Task value"

cat >"$tmpdir/spawn_async_block_ok.w" <<'EOF2'
fn main() -> i32 =
    spawn async: 40 + 2
    0
EOF2
expect_run_pass "$tmpdir/spawn_async_block_ok.w"

cat >"$tmpdir/spawn_non_task_literal_fail.w" <<'EOF3'
fn main() -> i32 =
    spawn 123
    0
EOF3
expect_check_fail_msg "$tmpdir/spawn_non_task_literal_fail.w" "spawn requires a Task value"

cat >"$tmpdir/spawn_non_task_call_fail.w" <<'EOF4'
fn sync_work() -> i32 =
    7

fn main() -> i32 =
    spawn sync_work()
    0
EOF4
expect_check_fail_msg "$tmpdir/spawn_non_task_call_fail.w" "spawn requires a Task value"

if [[ "$failures" -ne 0 ]]; then
  echo "phase4 spawn tests: $failures failure(s)"
  exit 1
fi

echo "phase4 spawn tests: PASS"
