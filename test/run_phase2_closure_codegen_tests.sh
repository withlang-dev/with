#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 closure-codegen tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(closure-codegen-run) $file"
  else
    echo "FAIL(closure-codegen-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(closure-codegen-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(closure-codegen-fail) $file"
  fi
}

cat >"$tmpdir/closure_codegen_noncapturing_ok.w" <<'EOF1'
fn main() -> i32 =
    let inc = |x| x + 1
    let add = |a, b| a + b
    if inc(4) == 5 and add(2, 3) == 5 then 0 else 1
EOF1
expect_run_pass "$tmpdir/closure_codegen_noncapturing_ok.w"

cat >"$tmpdir/closure_codegen_capturing_ok.w" <<'EOF2'
fn apply_twice(f: fn(i32) -> i32, x: i32) -> i32 =
    f(f(x))

fn main() -> i32 =
    let offset = 2
    let plus = |x| x + offset
    if plus(5) == 7 and apply_twice(plus, 3) == 7 then 0 else 1
EOF2
expect_run_pass "$tmpdir/closure_codegen_capturing_ok.w"

cat >"$tmpdir/closure_codegen_higher_order_ok.w" <<'EOF3'
fn apply(f: fn(i32) -> i32, x: i32) -> i32 =
    f(x)

fn main() -> i32 =
    let mul = |x| x * 3
    let out = apply(mul, 4)
    if out == 12 then 0 else 1
EOF3
expect_run_pass "$tmpdir/closure_codegen_higher_order_ok.w"

cat >"$tmpdir/closure_codegen_wrong_arity_fail.w" <<'EOF4'
fn main() -> i32 =
    let f = |x| x + 1
    let _bad = f(1, 2)
    0
EOF4
expect_check_fail "$tmpdir/closure_codegen_wrong_arity_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 closure-codegen tests: $failures failure(s)"
  exit 1
fi

echo "phase2 closure-codegen tests: PASS"
