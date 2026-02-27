#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 parameter-pattern tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(param-pattern-run) $file"
  else
    echo "FAIL(param-pattern-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(param-pattern-check-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(param-pattern-check-fail) $file"
  fi
}

cat >"$tmpdir/param_struct_shorthand_ok.w" <<'EOF1'
type Point = { x: i32, y: i32 }

fn sum({ x, y }: Point) -> i32:
    x + y

fn main -> i32:
    if sum(Point { x: 20, y: 22 }) == 42 then 0 else 1
EOF1
expect_run_pass "$tmpdir/param_struct_shorthand_ok.w"

cat >"$tmpdir/param_struct_rename_ok.w" <<'EOF2'
type Point = { x: i32, y: i32 }

fn distance2({ x: x1, y: y1 }: Point, { x: x2, y: y2 }: Point) -> i32:
    let dx = x2 - x1
    let dy = y2 - y1
    dx * dx + dy * dy

fn main -> i32:
    if distance2(Point { x: 0, y: 0 }, Point { x: 3, y: 4 }) == 25 then 0 else 1
EOF2
expect_run_pass "$tmpdir/param_struct_rename_ok.w"

cat >"$tmpdir/param_tuple_ok.w" <<'EOF3'
fn swap((a, b): (i32, i32)) -> (i32, i32):
    (b, a)

fn main -> i32:
    let out = swap((1, 2))
    if out.0 == 2 and out.1 == 1 then 0 else 1
EOF3
expect_run_pass "$tmpdir/param_tuple_ok.w"

cat >"$tmpdir/param_tuple_nested_ok.w" <<'EOF4'
fn flatten((a, (b, c)): (i32, (i32, i32))) -> i32:
    a + b + c

fn main -> i32:
    if flatten((1, (2, 3))) == 6 then 0 else 1
EOF4
expect_run_pass "$tmpdir/param_tuple_nested_ok.w"

cat >"$tmpdir/param_pattern_missing_type_fail.w" <<'EOF5'
type Point = { x: i32, y: i32 }

fn sum({ x, y }) -> i32:
    x + y

fn main -> i32: 0
EOF5
expect_check_fail "$tmpdir/param_pattern_missing_type_fail.w"

cat >"$tmpdir/param_pattern_unknown_field_fail.w" <<'EOF6'
type Point = { x: i32, y: i32 }

fn bad({ x, z }: Point) -> i32:
    x + z

fn main -> i32: 0
EOF6
expect_check_fail "$tmpdir/param_pattern_unknown_field_fail.w"

cat >"$tmpdir/param_tuple_invalid_literal_fail.w" <<'EOF7'
fn bad((1, b): (i32, i32)) -> i32:
    b

fn main -> i32: bad((1, 2))
EOF7
expect_check_fail "$tmpdir/param_tuple_invalid_literal_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 parameter-pattern tests: $failures failure(s)"
  exit 1
fi

echo "phase2 parameter-pattern tests: PASS"
