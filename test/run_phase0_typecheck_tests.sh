#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for typecheck tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "PASS(typecheck-pass) $file"
  else
    echo "FAIL(typecheck-pass) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(typecheck-negative) $file"
    failures=$((failures + 1))
  else
    echo "PASS(typecheck-negative) $file"
  fi
}

cat >"$tmpdir/typecheck_ok.w" <<'EOF'
fn add(a: i32, b: i32) -> i32:
    a + b

fn main -> i32:
    let i = 1
    let f = 2.5
    let b = true
    let s = "ok"
    let sum = add(i, 2)
    if b then
        if sum > 0 then 0 else 1
    else
        1
EOF
expect_check_pass "$tmpdir/typecheck_ok.w"

cat >"$tmpdir/return_mismatch.w" <<'EOF'
fn bad -> i32:
    true
EOF
expect_check_fail "$tmpdir/return_mismatch.w"

cat >"$tmpdir/call_arity_mismatch.w" <<'EOF'
fn add(a: i32, b: i32) -> i32:
    a + b

fn main -> i32:
    add(1)
EOF
expect_check_fail "$tmpdir/call_arity_mismatch.w"

cat >"$tmpdir/call_type_mismatch.w" <<'EOF'
fn add(a: i32, b: i32) -> i32:
    a + b

fn main -> i32:
    add(1, true)
EOF
expect_check_fail "$tmpdir/call_type_mismatch.w"

cat >"$tmpdir/operator_type_mismatch.w" <<'EOF'
fn main -> i32:
    1 + true
EOF
expect_check_fail "$tmpdir/operator_type_mismatch.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase0 typecheck tests: $failures failure(s)"
  exit 1
fi

echo "phase0 typecheck tests: PASS"

