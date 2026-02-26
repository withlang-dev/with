#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase3 std.random tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(random-check) $file"
  else
    echo "FAIL(random-check) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(random-run) $file"
  else
    echo "FAIL(random-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(random-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(random-run-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_pass "lib/std/random.w"
expect_run_pass "test/cases/import_std_random.w"

cat >"$tmpdir/std_random_extended_ok.w" <<'EOF1'
use std.random

fn main -> i32:
    seed(1234)
    let a1 = next_i32()
    let b1 = next_i32()
    seed(1234)
    let a2 = next_i32()
    let b2 = next_i32()
    assert(a1 == a2)
    assert(b1 == b2)

    let mut_ok = chance(100)
    assert(mut_ok)
    assert(not chance(0))
    assert(not chance(-10))
    assert(chance(110))

    assert(range_i32(5, 5) == 5)
    assert(range_i32(9, 3) == 9)

    var i: i32 = 0
    while i < 50:
        let v = range_i32(10, 20)
        assert(v >= 10)
        assert(v < 20)
        i = i + 1

    seed_now()
    let n = next_i32()
    assert(n >= 0)
EOF1
expect_run_pass "$tmpdir/std_random_extended_ok.w"

cat >"$tmpdir/std_random_seed_arity_fail.w" <<'EOF2'
use std.random

fn main -> i32:
    seed()
    0
EOF2
expect_run_fail "$tmpdir/std_random_seed_arity_fail.w"

cat >"$tmpdir/std_random_range_type_fail.w" <<'EOF3'
use std.random

fn main -> i32:
    let _x = range_i32("a", "b")
EOF3
expect_run_fail "$tmpdir/std_random_range_type_fail.w"

cat >"$tmpdir/std_random_chance_type_fail.w" <<'EOF4'
use std.random

fn main -> i32:
    let _x = chance("no")
EOF4
expect_run_fail "$tmpdir/std_random_chance_type_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase3 std.random tests: $failures failure(s)"
  exit 1
fi

echo "phase3 std.random tests: PASS"
