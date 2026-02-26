#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for llvm codegen tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_ir_pass() {
  local file="$1"
  local output
  if ! output=$("$WITH_BIN" ir "$file" 2>/dev/null); then
    echo "FAIL(llvm-ir) $file"
    failures=$((failures + 1))
    return
  fi
  if [[ "$output" != *"define i32 @main"* ]]; then
    echo "FAIL(llvm-ir-contents) $file"
    failures=$((failures + 1))
    return
  fi
  echo "PASS(llvm-ir) $file"
}

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(llvm-run) $file"
  else
    echo "FAIL(llvm-run) $file"
    failures=$((failures + 1))
  fi
}

expect_build_fail() {
  local file="$1"
  if "$WITH_BIN" build "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(llvm-negative-build) $file"
    failures=$((failures + 1))
  else
    echo "PASS(llvm-negative-build) $file"
  fi
}

cat >"$tmpdir/llvm_minimal.w" <<'EOF1'
fn add(a: i32, b: i32) -> i32 =
    a + b

fn main() -> i32 =
    if add(2, 3) == 5 then 0 else 1
EOF1
expect_ir_pass "$tmpdir/llvm_minimal.w"
expect_run_pass "$tmpdir/llvm_minimal.w"

cat >"$tmpdir/llvm_extern.w" <<'EOF2'
use c_import("#include <stdio.h>")

fn main() -> i32 =
    printf(c"%s %d\n", c"llvm", 1)
    0
EOF2
expect_ir_pass "$tmpdir/llvm_extern.w"
expect_run_pass "$tmpdir/llvm_extern.w"

cat >"$tmpdir/llvm_negative.w" <<'EOF3'
fn main() -> i32 =
    unknown_symbol(1)
EOF3
expect_build_fail "$tmpdir/llvm_negative.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase0 llvm codegen tests: $failures failure(s)"
  exit 1
fi

echo "phase0 llvm codegen tests: PASS"
