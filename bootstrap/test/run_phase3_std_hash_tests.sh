#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase3 std.hash tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(hash-check) $file"
  else
    echo "FAIL(hash-check) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(hash-run) $file"
  else
    echo "FAIL(hash-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(hash-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(hash-run-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_pass "lib/std/hash.w"
expect_run_pass "bootstrap/test/cases/import_std_hash.w"

cat >"$tmpdir/std_hash_extended_ok.w" <<'EOF1'
use std.hash

fn main -> i32:
    let e1 = hash_str("")
    let e2 = hash_str("")
    assert(e1 == e2)

    let h1 = hash_pair(100, 200)
    let h2 = combine(hash_i64(100), 200)
    assert(h1 == h2)

    var a = hasher()
    a.update_i64(1)
    a.update_i64(2)
    a.update_str("x")
    let av = a.finish()

    var b = hasher()
    b.update_i64(1)
    b.update_i64(2)
    b.update_str("x")
    let bv = b.finish()
    assert(av == bv)

    var c = hasher()
    c.update_str("x")
    c.update_i64(1)
    c.update_i64(2)
    let cv = c.finish()
    assert(av != cv)

    var d = default_hasher()
    d.update_i64(1)
    d.update_i64(2)
    d.update_str("x")
    assert(d.finish() == av)
EOF1
expect_run_pass "$tmpdir/std_hash_extended_ok.w"

cat >"$tmpdir/std_hash_update_arity_fail.w" <<'EOF2'
use std.hash

fn main -> i32:
    var h = hasher()
    h.update_i64()
    0
EOF2
expect_run_fail "$tmpdir/std_hash_update_arity_fail.w"

cat >"$tmpdir/std_hash_pair_type_fail.w" <<'EOF3'
use std.hash

fn main -> i32:
    let _x = hash_pair("a", "b")
EOF3
expect_run_fail "$tmpdir/std_hash_pair_type_fail.w"

cat >"$tmpdir/std_hash_default_arity_fail.w" <<'EOF4'
use std.hash

fn main -> i32:
    let _h = default_hasher(1)
EOF4
expect_run_fail "$tmpdir/std_hash_default_arity_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase3 std.hash tests: $failures failure(s)"
  exit 1
fi

echo "phase3 std.hash tests: PASS"
