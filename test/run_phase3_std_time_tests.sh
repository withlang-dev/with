#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase3 std.time tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(time-check) $file"
  else
    echo "FAIL(time-check) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(time-run) $file"
  else
    echo "FAIL(time-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(time-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(time-run-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_pass "lib/std/time.w"
expect_run_pass "test/cases/import_std_time.w"

cat >"$tmpdir/std_time_extended_ok.w" <<'EOF1'
use std.time

fn main -> i32:
    let t1 = now()
    let t2 = now()
    assert(t1 > 1000000000)
    assert(t2 >= t1)

    let c1 = clock_ticks()
    let c2 = clock_ticks()
    assert(c1 >= 0)
    assert(c2 >= c1)

    assert(sleep_secs(0) == 0)
EOF1
expect_run_pass "$tmpdir/std_time_extended_ok.w"

cat >"$tmpdir/std_time_now_arity_fail.w" <<'EOF2'
use std.time

fn main -> i32:
    let _t = now(1)
EOF2
expect_run_fail "$tmpdir/std_time_now_arity_fail.w"

cat >"$tmpdir/std_time_sleep_type_fail.w" <<'EOF3'
use std.time

fn main -> i32:
    let _x = sleep_secs("bad")
EOF3
expect_run_fail "$tmpdir/std_time_sleep_type_fail.w"

cat >"$tmpdir/std_time_clock_arity_fail.w" <<'EOF4'
use std.time

fn main -> i32:
    let _c = clock_ticks(1)
EOF4
expect_run_fail "$tmpdir/std_time_clock_arity_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase3 std.time tests: $failures failure(s)"
  exit 1
fi

echo "phase3 std.time tests: PASS"
