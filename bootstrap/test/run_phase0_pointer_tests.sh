#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for pointer tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "PASS(pointer-pass) $file"
  else
    echo "FAIL(pointer-pass) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(pointer-negative) $file"
    failures=$((failures + 1))
  else
    echo "PASS(pointer-negative) $file"
  fi
}

cat >"$tmpdir/pointer_ok.w" <<'EOF'
fn id_const(p: *const i32) -> *const i32:
    p

fn id_mut(p: *mut i32) -> *mut i32:
    p

fn main -> i32:
    0
EOF
expect_check_pass "$tmpdir/pointer_ok.w"

cat >"$tmpdir/pointer_mutability_mismatch.w" <<'EOF'
fn takes_const(p: *const i32) -> *const i32:
    p

fn main -> i32:
    let p: *mut i32 = 0 as *mut i32
    let _x = takes_const(p)
EOF
expect_check_fail "$tmpdir/pointer_mutability_mismatch.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase0 pointer tests: $failures failure(s)"
  exit 1
fi

echo "phase0 pointer tests: PASS"

