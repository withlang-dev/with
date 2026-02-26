#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 tuple-pattern tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(tuple-patterns-run) $file"
  else
    echo "FAIL(tuple-patterns-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(tuple-patterns-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(tuple-patterns-fail) $file"
  fi
}

cat >"$tmpdir/tuple_match_ok.w" <<'EOF1'
fn classify(p: (i32, i32)) -> i32:
    match p
        (0, 0) -> 100
        (x, 0) -> x
        _ -> -1

fn nested(p: ((i32, i32), i32)) -> i32:
    match p
        ((a, b), c) -> a + b + c

fn main -> i32:
    let ok =
        classify((0, 0)) == 100 and
        classify((7, 0)) == 7 and
        classify((3, 4)) == -1 and
        nested(((1, 2), 3)) == 6
    if ok then 0 else 1
EOF1
expect_run_pass "$tmpdir/tuple_match_ok.w"

cat >"$tmpdir/tuple_destructure_nested_ok.w" <<'EOF2'
fn main -> i32:
    let ((a, b), c) = ((1, 2), 3)
    let (x, (_, z)) = (10, (20, 30))
    let good = a == 1 and b == 2 and c == 3 and x == 10 and z == 30
    if good then 0 else 1
EOF2
expect_run_pass "$tmpdir/tuple_destructure_nested_ok.w"

cat >"$tmpdir/tuple_for_destructure_ok.w" <<'EOF3'
fn main -> i32:
    let pairs = [(1, 2), (3, 4)]
    let triples = [((1, 2), 3), ((4, 5), 6)]
    var sum = 0
    for (a, b) in pairs:
        sum = sum + a + b
    for ((x, y), z) in triples:
        sum = sum + x + y + z
    if sum == 31 then 0 else 1
EOF3
expect_run_pass "$tmpdir/tuple_for_destructure_ok.w"

cat >"$tmpdir/tuple_destructure_arity_fail.w" <<'EOF4'
fn main -> i32:
    let (a, b) = (1, 2, 3)
    a + b
EOF4
expect_check_fail "$tmpdir/tuple_destructure_arity_fail.w"

cat >"$tmpdir/tuple_destructure_literal_fail.w" <<'EOF5'
fn main -> i32:
    let (1, x) = (1, 2)
    x
EOF5
expect_check_fail "$tmpdir/tuple_destructure_literal_fail.w"

cat >"$tmpdir/tuple_for_non_tuple_fail.w" <<'EOF6'
fn main -> i32:
    var sum = 0
    for (a, b) in 0..3:
        sum = sum + a + b
    sum
EOF6
expect_check_fail "$tmpdir/tuple_for_non_tuple_fail.w"

cat >"$tmpdir/tuple_match_non_tuple_fail.w" <<'EOF7'
fn main -> i32:
    let x = 1
    let y = match x
        (a, b) -> a + b
        _ -> 0
    y
EOF7
expect_check_fail "$tmpdir/tuple_match_non_tuple_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 tuple-pattern tests: $failures failure(s)"
  exit 1
fi

echo "phase2 tuple-pattern tests: PASS"
