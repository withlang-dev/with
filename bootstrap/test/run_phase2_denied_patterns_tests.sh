#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 denied-patterns tests..."
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
      echo "PASS(denied-warn) $file"
    else
      echo "FAIL(denied-warn-msg) $file"
      failures=$((failures + 1))
    fi
  else
    echo "FAIL(denied-build) $file"
    failures=$((failures + 1))
  fi
  rm -f "$stderr_file"
}

expect_check_fail_msg() {
  local file="$1"
  local msg="$2"
  local stderr_file="$tmpdir/stderr.err.$$"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$stderr_file"; then
    echo "FAIL(denied-check-fail) $file"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(denied-check-fail) $file"
    else
      echo "FAIL(denied-check-msg) $file"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$stderr_file"
}

cat >"$tmpdir/denied_e0802_unused_result_option_warn.w" <<'EOF1'
fn fallible -> Result[i32, i32]: Err(1)

fn main -> i32:
    fallible()
    0
EOF1
expect_build_warn_msg "$tmpdir/denied_e0802_unused_result_option_warn.w" "E0802: unused Result/Option value"

cat >"$tmpdir/denied_e0801_unused_task_warn.w" <<'EOF2'
async fn work -> i32:
    1

fn main -> i32:
    work()
    0
EOF2
expect_build_warn_msg "$tmpdir/denied_e0801_unused_task_warn.w" "E0801: unused Task value"

cat >"$tmpdir/denied_e0901_unnecessary_unsafe_warn.w" <<'EOF3'
fn main -> i32:
    unsafe:
        0
EOF3
expect_build_warn_msg "$tmpdir/denied_e0901_unnecessary_unsafe_warn.w" "E0901: unnecessary unsafe block"

cat >"$tmpdir/denied_e0601_unreachable_warn.w" <<'EOF4'
fn main -> i32:
    return 0
    1
EOF4
expect_build_warn_msg "$tmpdir/denied_e0601_unreachable_warn.w" "E0601: unreachable code after return/break/continue"

cat >"$tmpdir/denied_e0201_implicit_narrowing_fail.w" <<'EOF5'
fn main -> i32:
    let x: i8 = 300
    x
EOF5
expect_check_fail_msg "$tmpdir/denied_e0201_implicit_narrowing_fail.w" "E0201: implicit narrowing conversion"

cat >"$tmpdir/denied_e0701_may_suspend_guard_fail.w" <<'EOF6'
fn task -> i32: 1

fn main -> i32:
    let lock_guard = 1
    let _x = task().await
EOF6
expect_check_fail_msg "$tmpdir/denied_e0701_may_suspend_guard_fail.w" "E0701: may_suspend call while no_await_guard value is live"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 denied-patterns tests: $failures failure(s)"
  exit 1
fi

echo "phase2 denied-patterns tests: PASS"
