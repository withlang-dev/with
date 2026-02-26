#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 comprehension tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(comprehension-run) $file"
  else
    echo "FAIL(comprehension-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(comprehension-check-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(comprehension-check-fail) $file"
  fi
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(comprehension-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(comprehension-run-fail) $file"
  fi
}

cat >"$tmpdir/comprehension_basic_ok.w" <<'EOF1'
fn main -> i32:
    let squares = [x * x for x in 0..5]
    if squares[0] == 0 and squares[1] == 1 and squares[4] == 16 then 0 else 1
EOF1
expect_run_pass "$tmpdir/comprehension_basic_ok.w"

cat >"$tmpdir/comprehension_filter_ok.w" <<'EOF2'
fn main -> i32:
    let evens = [x for x in 0..10 if x % 2 == 0]
    let ok =
        evens[0] == 0 and
        evens[1] == 2 and
        evens[2] == 4 and
        evens[3] == 6 and
        evens[4] == 8
    if ok then 0 else 1
EOF2
expect_run_pass "$tmpdir/comprehension_filter_ok.w"

cat >"$tmpdir/comprehension_nested_ok.w" <<'EOF3'
fn main -> i32:
    let pairs = [x * 10 + y for x in 0..3 for y in 0..3 if x != y]
    let ok =
        pairs[0] == 1 and
        pairs[1] == 2 and
        pairs[2] == 10 and
        pairs[3] == 12 and
        pairs[4] == 20 and
        pairs[5] == 21
    if ok then 0 else 1
EOF3
expect_run_pass "$tmpdir/comprehension_nested_ok.w"

cat >"$tmpdir/comprehension_three_for_ok.w" <<'EOF4'
fn main -> i32:
    let vals = [x * 100 + y * 10 + z for x in 0..2 for y in 0..2 for z in 0..2]
    let ok =
        vals[0] == 0 and
        vals[1] == 1 and
        vals[2] == 10 and
        vals[3] == 11 and
        vals[4] == 100 and
        vals[5] == 101 and
        vals[6] == 110 and
        vals[7] == 111
    if ok then 0 else 1
EOF4
expect_run_pass "$tmpdir/comprehension_three_for_ok.w"

cat >"$tmpdir/comprehension_non_range_iter_fail.w" <<'EOF5'
fn main -> i32:
    let xs = [1, 2, 3]
    let ys = [x for x in xs]
    ys[0]
EOF5
expect_run_fail "$tmpdir/comprehension_non_range_iter_fail.w"

cat >"$tmpdir/comprehension_parse_fail.w" <<'EOF6'
fn main -> i32:
    let xs = [x for x 0..3]
    xs[0]
EOF6
expect_check_fail "$tmpdir/comprehension_parse_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 comprehension tests: $failures failure(s)"
  exit 1
fi

echo "phase2 comprehension tests: PASS"
