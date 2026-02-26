#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 pipeline-ops tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(pipeline-ops-run) $file"
  else
    echo "FAIL(pipeline-ops-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(pipeline-ops-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(pipeline-ops-fail) $file"
  fi
}

cat >"$tmpdir/pipeline_forward_ok.w" <<'EOF1'
fn inc(x: i32) -> i32: x + 1
fn add(a: i32, b: i32) -> i32: a + b
fn mul(a: i32, b: i32) -> i32: a * b

fn main -> i32:
    let a = 5 |> inc
    let b = 4 |> add(3)
    let c = 3 |> add(2) |> mul(4)
    if a == 6 and b == 7 and c == 20 then 0 else 1
EOF1
expect_run_pass "$tmpdir/pipeline_forward_ok.w"

cat >"$tmpdir/pipeline_backward_apply_ok.w" <<'EOF2'
fn inc(x: i32) -> i32: x + 1

fn main -> i32:
    let out = inc <| 41
    if out == 42 then 0 else 1
EOF2
expect_run_pass "$tmpdir/pipeline_backward_apply_ok.w"

cat >"$tmpdir/pipeline_compose_ok.w" <<'EOF3'
fn double(x: i32) -> i32: x * 2
fn add1(x: i32) -> i32: x + 1

fn main -> i32:
    let f = double >> add1
    let g = add1 << double
    if f(5) == 11 and g(5) == 11 then 0 else 1
EOF3
expect_run_pass "$tmpdir/pipeline_compose_ok.w"

cat >"$tmpdir/pipeline_bad_rhs_fail.w" <<'EOF4'
fn main -> i32:
    let _bad = 1 |> 2
EOF4
expect_check_fail "$tmpdir/pipeline_bad_rhs_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 pipeline-ops tests: $failures failure(s)"
  exit 1
fi

echo "phase2 pipeline-ops tests: PASS"
