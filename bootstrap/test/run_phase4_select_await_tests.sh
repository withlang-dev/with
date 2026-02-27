#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase4 select-await tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(select-await-run) $file"
  else
    echo "FAIL(select-await-run) $file"
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
    echo "FAIL(select-await-check-fail) $file"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(select-await-check-fail) $file"
    else
      echo "FAIL(select-await-check-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$stderr_file"
}

expect_run_pass "bootstrap/test/cases/select_await.w"
expect_run_pass "bootstrap/test/cases/select_await_three.w"

cat >"$tmpdir/select_await_first_ready_second_arm.w" <<'EOF1'
async fn slow -> i32:
    let _ = (async: 0).await
    10

async fn fast -> i32: 20

fn main -> i32:
    let r = select await:
        a = slow() -> a
        b = fast() -> b
    if r == 20 then 0 else 1
EOF1
expect_run_pass "$tmpdir/select_await_first_ready_second_arm.w"

cat >"$tmpdir/select_await_arm_binding_scope_fail.w" <<'EOF2'
async fn work -> i32: 1

fn main -> i32:
    let v = select await:
        x = work() -> x
    x + v
EOF2
expect_check_fail_msg "$tmpdir/select_await_arm_binding_scope_fail.w" "undefined variable"

cat >"$tmpdir/select_await_non_task_fail.w" <<'EOF3'
fn main -> i32:
    let r = select await:
        x = 123 -> x
    r
EOF3
expect_check_fail_msg "$tmpdir/select_await_non_task_fail.w" "select await arm requires a Task value"

cat >"$tmpdir/select_await_empty_fail.w" <<'EOF4'
fn main -> i32:
    select await:
EOF4
expect_check_fail_msg "$tmpdir/select_await_empty_fail.w" "select await requires at least one arm"

if [[ "$failures" -ne 0 ]]; then
  echo "phase4 select-await tests: $failures failure(s)"
  exit 1
fi

echo "phase4 select-await tests: PASS"
