#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase3 std.alloc tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(alloc-check) $file"
  else
    echo "FAIL(alloc-check) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(alloc-run) $file"
  else
    echo "FAIL(alloc-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(alloc-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(alloc-run-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_pass "lib/std/alloc.w"
expect_run_pass "bootstrap/test/cases/import_std_alloc.w"

cat >"$tmpdir/std_alloc_extended_ok.w" <<'EOF1'
use std.alloc

fn main -> i32:
    let arena = arena_new(64)
    let p1 = arena_alloc(arena, 0)
    assert(p1 != 0)
    arena_free(arena, p1)

    let p2 = arena_alloc(arena, 16)
    assert(p2 != 0)
    arena_free(arena, p2)

    let z = arena_alloc_zeroed(arena, 4, 8)
    assert(z != 0)
    arena_free(arena, z)
    arena_reset(arena)

    let pool_small = pool_new(0, 3)
    let q1 = pool_alloc(pool_small)
    assert(q1 != 0)
    pool_free(pool_small, q1)

    let pool = pool_new(24, 8)
    let q2 = pool_alloc(pool)
    assert(q2 != 0)
    pool_free(pool, q2)
    0
EOF1
expect_run_pass "$tmpdir/std_alloc_extended_ok.w"

cat >"$tmpdir/std_alloc_arena_new_type_fail.w" <<'EOF2'
use std.alloc

fn main -> i32:
    let _a = arena_new("x")
EOF2
expect_run_fail "$tmpdir/std_alloc_arena_new_type_fail.w"

cat >"$tmpdir/std_alloc_arena_alloc_arity_fail.w" <<'EOF3'
use std.alloc

fn main -> i32:
    let a = arena_new(8)
    let _p = arena_alloc(a)
EOF3
expect_run_fail "$tmpdir/std_alloc_arena_alloc_arity_fail.w"

cat >"$tmpdir/std_alloc_pool_new_arity_fail.w" <<'EOF4'
use std.alloc

fn main -> i32:
    let _p = pool_new(8)
EOF4
expect_run_fail "$tmpdir/std_alloc_pool_new_arity_fail.w"

cat >"$tmpdir/std_alloc_pool_free_type_fail.w" <<'EOF5'
use std.alloc

fn main -> i32:
    let p = pool_new(8, 2)
    pool_free(p, 123)
    0
EOF5
expect_run_fail "$tmpdir/std_alloc_pool_free_type_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase3 std.alloc tests: $failures failure(s)"
  exit 1
fi

echo "phase3 std.alloc tests: PASS"
