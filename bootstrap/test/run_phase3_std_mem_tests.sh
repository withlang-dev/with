#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase3 std.mem tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(std-mem-check) $file"
  else
    echo "FAIL(std-mem-check) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(std-mem-run) $file"
  else
    echo "FAIL(std-mem-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(std-mem-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(std-mem-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_pass "lib/std/mem.w"

expect_run_pass "bootstrap/test/cases/import_std_mem.w"

cat >"$tmpdir/std_mem_copy_compare_ok.w" <<'EOF1'
use std.mem

fn main -> i32:
    let a = alloc(16)
    let b = alloc_zeroed(16, 1)
    assert(a != 0)
    assert(b != 0)

    mem_set(a, 65, 16)
    mem_copy(b, a, 16)
    assert(mem_cmp(a, b, 16) == 0)

    let grown = realloc_mem(a, 32)
    assert(grown != 0)

    free_mem(grown)
    free_mem(b)
    0
EOF1
expect_run_pass "$tmpdir/std_mem_copy_compare_ok.w"

cat >"$tmpdir/std_mem_move_ok.w" <<'EOF2'
use std.mem

fn main -> i32:
    let a = alloc(8)
    assert(a != 0)
    mem_set(a, 90, 8)
    let shifted = mem_move(a, a, 8)
    assert(shifted != 0)
    free_mem(a)
    0
EOF2
expect_run_pass "$tmpdir/std_mem_move_ok.w"

cat >"$tmpdir/std_mem_alloc_bad_arg_fail.w" <<'EOF3'
use std.mem

fn main -> i32:
    let _bad = alloc(true)
EOF3
expect_check_fail "$tmpdir/std_mem_alloc_bad_arg_fail.w"

cat >"$tmpdir/std_mem_set_bad_len_fail.w" <<'EOF4'
use std.mem

fn main -> i32:
    let p = alloc(4)
    mem_set(p, 0, false)
    free_mem(p)
    0
EOF4
expect_check_fail "$tmpdir/std_mem_set_bad_len_fail.w"

cat >"$tmpdir/std_mem_free_bad_ptr_fail.w" <<'EOF5'
use std.mem

fn main -> i32:
    free_mem(1)
    0
EOF5
expect_check_fail "$tmpdir/std_mem_free_bad_ptr_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase3 std.mem tests: $failures failure(s)"
  exit 1
fi

echo "phase3 std.mem tests: PASS"
