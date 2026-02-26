#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase3 std.sync tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(sync-check) $file"
  else
    echo "FAIL(sync-check) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(sync-run) $file"
  else
    echo "FAIL(sync-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(sync-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(sync-run-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_pass "lib/std/sync.w"
expect_run_pass "test/cases/import_std_sync.w"

cat >"$tmpdir/std_sync_extended_ok.w" <<'EOF1'
use std.sync

fn main() -> i32 =
    var m = mutex_new(3)
    assert(mutex_get(m) == 3)
    mutex_set(&mut m, 8)
    assert(mutex_get(m) == 8)

    var rw = rwlock_new(11)
    assert(rwlock_read(rw) == 11)
    rwlock_write(&mut rw, -2)
    assert(rwlock_read(rw) == -2)

    var a = atomic_new(9)
    let sum = atomic_add(&mut a, 6)
    assert(sum == 15)
    assert(atomic_load(a) == 15)

    var b = atomic_new(0)
    atomic_store(&mut b, -7)
    assert(atomic_load(b) == -7)
    0
EOF1
expect_run_pass "$tmpdir/std_sync_extended_ok.w"

cat >"$tmpdir/std_sync_mutex_set_borrow_fail.w" <<'EOF2'
use std.sync

fn main() -> i32 =
    let m = mutex_new(1)
    mutex_set(m, 2)
    0
EOF2
expect_run_fail "$tmpdir/std_sync_mutex_set_borrow_fail.w"

cat >"$tmpdir/std_sync_atomic_add_arity_fail.w" <<'EOF3'
use std.sync

fn main() -> i32 =
    var a = atomic_new(1)
    let _x = atomic_add(&mut a)
    0
EOF3
expect_run_fail "$tmpdir/std_sync_atomic_add_arity_fail.w"

cat >"$tmpdir/std_sync_rwlock_write_type_fail.w" <<'EOF4'
use std.sync

fn main() -> i32 =
    var rw = rwlock_new(1)
    rwlock_write(&mut rw, "x")
    0
EOF4
expect_run_fail "$tmpdir/std_sync_rwlock_write_type_fail.w"

cat >"$tmpdir/std_sync_atomic_load_type_fail.w" <<'EOF5'
use std.sync

fn main() -> i32 =
    let _x = atomic_load(123)
    0
EOF5
expect_run_fail "$tmpdir/std_sync_atomic_load_type_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase3 std.sync tests: $failures failure(s)"
  exit 1
fi

echo "phase3 std.sync tests: PASS"
