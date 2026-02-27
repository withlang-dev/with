#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 slice-pattern tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(slice-pattern-run) $file"
  else
    echo "FAIL(slice-pattern-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(slice-pattern-check-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(slice-pattern-check-fail) $file"
  fi
}

cat >"$tmpdir/slice_exact_and_fallback_ok.w" <<'EOF1'
fn main -> i32:
    let arr = [1, 2, 3]
    let v = match arr
        [a, b, c] -> a + b + c
        _ -> 0
    let short = [7, 8]
    let w = match short
        [x, y, z] -> x + y + z
        _ -> 99
    if v == 6 and w == 99 then 0 else 1
EOF1
expect_run_pass "$tmpdir/slice_exact_and_fallback_ok.w"

cat >"$tmpdir/slice_rest_and_tail_ok.w" <<'EOF2'
fn main -> i32:
    let arr = [10, 20, 30, 40, 50]
    let v = match arr
        [first, ..middle, last] ->
            if first == 10 and middle == 3 and last == 50 then 1 else 0
        _ -> 0
    if v == 1 then 0 else 1
EOF2
expect_run_pass "$tmpdir/slice_rest_and_tail_ok.w"

cat >"$tmpdir/slice_rest_no_binding_ok.w" <<'EOF3'
fn main -> i32:
    let arr = [4, 5, 6]
    let v = match arr
        [_, .., tail] -> tail
        _ -> 0
    if v == 6 then 0 else 1
EOF3
expect_run_pass "$tmpdir/slice_rest_no_binding_ok.w"

cat >"$tmpdir/slice_non_array_fail.w" <<'EOF4'
fn main -> i32:
    let v = match 42
        [x, ..rest] -> x + rest as i32
        _ -> 0
    v
EOF4
expect_check_fail "$tmpdir/slice_non_array_fail.w"

cat >"$tmpdir/slice_multiple_rest_fail.w" <<'EOF5'
fn main -> i32:
    let arr = [1, 2, 3]
    let _v = match arr
        [a, ..r1, ..r2] -> a
        _ -> 0
    0
EOF5
expect_check_fail "$tmpdir/slice_multiple_rest_fail.w"

cat >"$tmpdir/slice_rest_dotdot_eq_fail.w" <<'EOF6'
fn main -> i32:
    let arr = [1, 2, 3]
    let _v = match arr
        [a, ..=rest] -> a
        _ -> 0
    0
EOF6
expect_check_fail "$tmpdir/slice_rest_dotdot_eq_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 slice-pattern tests: $failures failure(s)"
  exit 1
fi

echo "phase2 slice-pattern tests: PASS"
