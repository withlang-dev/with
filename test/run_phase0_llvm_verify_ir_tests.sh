#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for llvm verify/ir tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_ir_ok() {
  local file="$1"
  local must_have="$2"
  local out
  if ! out=$("$WITH_BIN" ir "$file" 2>/dev/null); then
    echo "FAIL(llvm-verify-ir) $file"
    failures=$((failures + 1))
    return
  fi
  if [[ "$out" != *"$must_have"* ]]; then
    echo "FAIL(llvm-ir-content) $file"
    failures=$((failures + 1))
    return
  fi
  echo "PASS(llvm-verify-ir) $file"
}

expect_ir_fail() {
  local file="$1"
  if "$WITH_BIN" ir "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(llvm-ir-negative) $file"
    failures=$((failures + 1))
  else
    echo "PASS(llvm-ir-negative) $file"
  fi
}

cat >"$tmpdir/llvm_ir_simple.w" <<'EOF1'
fn mul(a: i32, b: i32) -> i32 =
    a * b

fn main() -> i32 =
    mul(3, 4)
EOF1
expect_ir_ok "$tmpdir/llvm_ir_simple.w" "define i32 @main"

cat >"$tmpdir/llvm_ir_cimport.w" <<'EOF2'
use c_import("#include <stdio.h>")

fn main() -> i32 =
    printf(c"%s %d\n", c"verify", 7)
    0
EOF2
expect_ir_ok "$tmpdir/llvm_ir_cimport.w" "declare i32 @printf"

cat >"$tmpdir/llvm_ir_parse_fail.w" <<'EOF3'
fn main() -> i32 =
    let x =
EOF3
expect_ir_fail "$tmpdir/llvm_ir_parse_fail.w"

cat >"$tmpdir/llvm_ir_type_fail.w" <<'EOF4'
fn main() -> i32 =
    missing_symbol(1)
EOF4
expect_ir_fail "$tmpdir/llvm_ir_type_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase0 llvm verify/ir tests: $failures failure(s)"
  exit 1
fi

echo "phase0 llvm verify/ir tests: PASS"
