#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase4 async-scope tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(async-scope-run) $file"
  else
    echo "FAIL(async-scope-run) $file"
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
    echo "FAIL(async-scope-check-fail) $file"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(async-scope-check-fail) $file"
    else
      echo "FAIL(async-scope-check-msg) $file"
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
      echo "FAIL(async-scope-unexpected-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    else
      echo "PASS(async-scope-no-msg) $file"
    fi
  else
    echo "FAIL(async-scope-build) $file"
    cat "$stderr_file"
    failures=$((failures + 1))
  fi
  rm -f "$stderr_file"
}

expect_run_pass "test/cases/async_scope.w"
expect_run_pass "test/cases/p4_async_scope.w"

cat >"$tmpdir/async_scope_track_and_await.w" <<'EOF1'
async fn one() -> i32 = 1
async fn two() -> i32 = 2

fn main() -> i32 =
    let sum = async scope |s|:
        let a = s.track(one())
        let b = s.track(two())
        a.await + b.await
    if sum == 3 then 0 else 1
EOF1
expect_run_pass "$tmpdir/async_scope_track_and_await.w"

cat >"$tmpdir/async_scope_drop_scoped_task_ok.w" <<'EOF2'
async fn work() -> i32 = 1

fn main() -> i32 =
    async scope |s|:
        s.track(work())
    0
EOF2
expect_run_pass "$tmpdir/async_scope_drop_scoped_task_ok.w"
expect_build_pass_no_msg "$tmpdir/async_scope_drop_scoped_task_ok.w" "E0801: unused Task value"

cat >"$tmpdir/async_scope_track_non_task_fail.w" <<'EOF3'
fn main() -> i32 =
    async scope |s|:
        s.track(123)
    0
EOF3
expect_check_fail_msg "$tmpdir/async_scope_track_non_task_fail.w" "track() requires a Task value"

cat >"$tmpdir/async_scope_track_outside_fail.w" <<'EOF4'
fn main() -> i32 =
    let s = 1
    s.track(async: 1)
    0
EOF4
expect_check_fail_msg "$tmpdir/async_scope_track_outside_fail.w" "track() is only available inside async scope"

if [[ "$failures" -ne 0 ]]; then
  echo "phase4 async-scope tests: $failures failure(s)"
  exit 1
fi

echo "phase4 async-scope tests: PASS"
