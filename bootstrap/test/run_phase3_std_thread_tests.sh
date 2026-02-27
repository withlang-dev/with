#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase3 std.thread tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(thread-check) $file"
  else
    echo "FAIL(thread-check) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(thread-run) $file"
  else
    echo "FAIL(thread-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(thread-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(thread-run-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_pass "lib/std/thread.w"
expect_run_pass "bootstrap/test/cases/import_std_thread.w"

cat >"$tmpdir/std_thread_extended_ok.w" <<'EOF1'
use std.thread

fn worker_a -> i32:
    7

fn worker_b -> i32:
    19

fn worker_c -> i32:
    -4

fn main -> i32:
    let a = join(spawn_os(worker_a))
    let b = join(spawn_os(worker_b))
    let c = join(spawn_os(worker_c))
    assert(a == 7)
    assert(b == 19)
    assert(c == -4)
    assert(a + b + c == 22)
EOF1
expect_run_pass "$tmpdir/std_thread_extended_ok.w"

cat >"$tmpdir/std_thread_spawn_arity_fail.w" <<'EOF2'
use std.thread

fn worker -> i32:
    1

fn main -> i32:
    let _h = spawn_os(worker, worker)
EOF2
expect_run_fail "$tmpdir/std_thread_spawn_arity_fail.w"

cat >"$tmpdir/std_thread_spawn_sig_fail.w" <<'EOF3'
use std.thread

fn main -> i32:
    let _h = spawn_os(123)
EOF3
expect_run_fail "$tmpdir/std_thread_spawn_sig_fail.w"

cat >"$tmpdir/std_thread_join_type_fail.w" <<'EOF4'
use std.thread

fn main -> i32:
    let _x = join(123)
EOF4
expect_run_fail "$tmpdir/std_thread_join_type_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase3 std.thread tests: $failures failure(s)"
  exit 1
fi

echo "phase3 std.thread tests: PASS"
