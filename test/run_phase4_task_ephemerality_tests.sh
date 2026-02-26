#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase4 task-ephemerality tests..."
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
      echo "PASS(task-ephemeral-warn) $file"
    else
      echo "FAIL(task-ephemeral-warn-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  else
    echo "FAIL(task-ephemeral-build) $file"
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
      echo "FAIL(task-ephemeral-unexpected-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    else
      echo "PASS(task-ephemeral-no-msg) $file"
    fi
  else
    echo "FAIL(task-ephemeral-build) $file"
    cat "$stderr_file"
    failures=$((failures + 1))
  fi
  rm -f "$stderr_file"
}

cat >"$tmpdir/task_ephemeral_borrow_warn.w" <<'EOF1'
async fn borrow(x: &mut i32) -> i32:
    *x

fn sink(t: i32) -> i32:
    t

fn main -> i32:
    let mut x = 7
    let t = borrow(&mut x)
    sink(t)
    0
EOF1
expect_build_warn_msg "$tmpdir/task_ephemeral_borrow_warn.w" "ephemeral Task passed by value may escape"

cat >"$tmpdir/task_ephemeral_assign_warn.w" <<'EOF2'
async fn borrow(x: &mut i32) -> i32:
    *x

fn sink(t: i32) -> i32:
    t

fn main -> i32:
    let mut x = 9
    let t1 = borrow(&mut x)
    let t2 = t1
    sink(t2)
    0
EOF2
expect_build_warn_msg "$tmpdir/task_ephemeral_assign_warn.w" "ephemeral Task passed by value may escape"

cat >"$tmpdir/task_ephemeral_async_block_warn.w" <<'EOF3'
fn sink(t: i32) -> i32:
    t

fn main -> i32:
    let mut x = 3
    let r = &mut x
    let t = async: *r
    sink(t)
    0
EOF3
expect_build_warn_msg "$tmpdir/task_ephemeral_async_block_warn.w" "ephemeral Task passed by value may escape"

cat >"$tmpdir/task_ephemeral_owned_ok.w" <<'EOF4'
async fn owned(x: i32) -> i32:
    x + 1

fn sink(t: i32) -> i32:
    t

fn main -> i32:
    let t = owned(1)
    sink(t)
    0
EOF4
expect_build_pass_no_msg "$tmpdir/task_ephemeral_owned_ok.w" "ephemeral Task passed by value may escape"

cat >"$tmpdir/task_ephemeral_byref_ok.w" <<'EOF5'
async fn borrow(x: &mut i32) -> i32:
    *x

fn inspect(t: &i32) -> i32:
    *t

fn main -> i32:
    let mut x = 11
    let t = borrow(&mut x)
    inspect(&t)
    0
EOF5
expect_build_pass_no_msg "$tmpdir/task_ephemeral_byref_ok.w" "ephemeral Task passed by value may escape"

if [[ "$failures" -ne 0 ]]; then
  echo "phase4 task-ephemerality tests: $failures failure(s)"
  exit 1
fi

echo "phase4 task-ephemerality tests: PASS"
