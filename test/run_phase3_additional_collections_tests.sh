#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase3 additional collections tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(additional-collections-check) $file"
  else
    echo "FAIL(additional-collections-check) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(additional-collections-run) $file"
  else
    echo "FAIL(additional-collections-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(additional-collections-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(additional-collections-run-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_pass "lib/std/collections.w"
expect_run_pass "test/cases/import_std_collections_additional.w"

cat >"$tmpdir/additional_collections_extended_ok.w" <<'EOF1'
use std.collections

fn main -> i32:
    var sm = slotmap_new()
    let ins = slotmap_insert(sm, 99)
    sm = ins.0
    let h = ins.1
    let wrong_generation = Handle { key: h.key, generation: h.generation + 1 }
    assert(slotmap_get(sm, wrong_generation).is_none())
    assert(not slotmap_contains(sm, wrong_generation))
    let rm = slotmap_remove(sm, wrong_generation)
    sm = rm.0
    assert(not (rm.1))
    assert(slotmap_get(sm, h).unwrap() == 99)

    var bt = btree_new()
    bt = btree_insert(bt, "k", 4)
    bt = btree_insert(bt, "k", 8)
    assert(btree_len(bt) == 1)
    assert(btree_get(bt, "k").unwrap() == 8)
EOF1
expect_run_pass "$tmpdir/additional_collections_extended_ok.w"

cat >"$tmpdir/additional_collections_slotmap_insert_type_fail.w" <<'EOF2'
use std.collections

fn main -> i32:
    var sm = slotmap_new()
    let _h = slotmap_insert(sm, "bad")
EOF2
expect_run_fail "$tmpdir/additional_collections_slotmap_insert_type_fail.w"

cat >"$tmpdir/additional_collections_slotmap_get_handle_fail.w" <<'EOF3'
use std.collections

fn main -> i32:
    let sm = slotmap_new()
    let _v = slotmap_get(sm, 123)
EOF3
expect_run_fail "$tmpdir/additional_collections_slotmap_get_handle_fail.w"

cat >"$tmpdir/additional_collections_btree_insert_arity_fail.w" <<'EOF4'
use std.collections

fn main -> i32:
    var bt = btree_new()
    btree_insert(bt, "x")
EOF4
expect_run_fail "$tmpdir/additional_collections_btree_insert_arity_fail.w"

cat >"$tmpdir/additional_collections_btree_remove_type_fail.w" <<'EOF5'
use std.collections

fn main -> i32:
    var bt = btree_new()
    let _ok = btree_remove(bt, 12)
EOF5
expect_run_fail "$tmpdir/additional_collections_btree_remove_type_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase3 additional collections tests: $failures failure(s)"
  exit 1
fi

echo "phase3 additional collections tests: PASS"
