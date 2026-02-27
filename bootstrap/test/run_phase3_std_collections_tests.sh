#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase3 std.collections tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(std-collections-check) $file"
  else
    echo "FAIL(std-collections-check) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(std-collections-run) $file"
  else
    echo "FAIL(std-collections-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(std-collections-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(std-collections-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_pass "lib/std/collections.w"

expect_run_pass "bootstrap/test/cases/import_std_collections.w"
expect_run_pass "bootstrap/test/cases/vec.w"
expect_run_pass "bootstrap/test/cases/vec_push_pop.w"
expect_run_pass "bootstrap/test/cases/vec_methods.w"
expect_run_pass "bootstrap/test/cases/vec_iteration.w"
expect_run_pass "bootstrap/test/cases/vec_map_filter.w"
expect_run_pass "bootstrap/test/cases/hashmap.w"
expect_run_pass "bootstrap/test/cases/hashmap_basic.w"
expect_run_pass "bootstrap/test/cases/hashmap_int.w"
expect_run_pass "bootstrap/test/cases/hashmap_ops.w"
expect_run_pass "bootstrap/test/cases/hashset.w"
expect_run_pass "bootstrap/test/cases/hashset_ops.w"
expect_run_pass "bootstrap/test/cases/hashmap_convenience.w"

cat >"$tmpdir/std_collections_bad_increment_key_fail.w" <<'EOF1'
use std.collections

fn main -> i32:
    var counts: HashMap[str, i32] = HashMap.new()
    increment(counts, 123)
    0
EOF1
expect_check_fail "$tmpdir/std_collections_bad_increment_key_fail.w"

cat >"$tmpdir/std_collections_bad_append_arity_fail.w" <<'EOF2'
use std.collections

fn main -> i32:
    var grouped: HashMap[str, Vec[i32]] = HashMap.new()
    append(grouped, "vals")
EOF2
expect_check_fail "$tmpdir/std_collections_bad_append_arity_fail.w"

cat >"$tmpdir/std_collections_bad_update_arity_fail.w" <<'EOF3'
use std.collections

fn plus_one(x: i32) -> i32:
    x + 1

fn main -> i32:
    var counts: HashMap[str, i32] = HashMap.new()
    update(counts, "a", plus_one)
    0
EOF3
expect_check_fail "$tmpdir/std_collections_bad_update_arity_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase3 std.collections tests: $failures failure(s)"
  exit 1
fi

echo "phase3 std.collections tests: PASS"
