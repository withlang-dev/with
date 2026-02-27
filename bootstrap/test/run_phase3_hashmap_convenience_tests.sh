#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase3 HashMap convenience tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(hashmap-conv-run) $file"
  else
    echo "FAIL(hashmap-conv-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(hashmap-conv-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(hashmap-conv-run-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(hashmap-conv-check-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(hashmap-conv-check-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_pass "bootstrap/test/cases/hashmap_convenience.w"
expect_run_pass "bootstrap/test/cases/import_std_collections.w"

cat >"$tmpdir/hashmap_convenience_semantics_ok.w" <<'EOF1'
fn plus_ten(x: i32) -> i32:
    x + 10

fn main -> i32:
    var counts: HashMap[str, i32] = HashMap.new()

    // increment/decrement on missing keys use 0 baseline.
    counts.increment("x")
    counts.increment("x")
    counts.decrement("x")
    assert(counts.get("x").unwrap() == 1)

    counts.decrement("missing")
    assert(counts.get("missing").unwrap() == 0 - 1)

    // update inserts default when key missing, then maps existing values.
    counts.update("k", 7, plus_ten)
    assert(counts.get("k").unwrap() == 7)
    counts.update("k", 7, plus_ten)
    assert(counts.get("k").unwrap() == 17)

    // append initializes Vec on missing key and appends on existing key.
    var grouped: HashMap[str, Vec[i32]] = HashMap.new()
    grouped.append("nums", 3)
    grouped.append("nums", 4)
    grouped.append("nums", 5)
    let nums = grouped.get("nums").unwrap()
    assert(nums.len() == 3)
    assert(nums.get(0) == 3)
    assert(nums.get(2) == 5)
EOF1
expect_run_pass "$tmpdir/hashmap_convenience_semantics_ok.w"

cat >"$tmpdir/hashmap_convenience_bad_increment_fail.w" <<'EOF2'
fn main -> i32:
    var m: HashMap[str, str] = HashMap.new()
    m.insert("a", "b")
    m.increment("a")
    0
EOF2
expect_run_fail "$tmpdir/hashmap_convenience_bad_increment_fail.w"

cat >"$tmpdir/hashmap_convenience_bad_append_fail.w" <<'EOF3'
fn main -> i32:
    var m: HashMap[str, i32] = HashMap.new()
    m.append("a", 1)
EOF3
expect_run_fail "$tmpdir/hashmap_convenience_bad_append_fail.w"

cat >"$tmpdir/hashmap_convenience_bad_wrapper_key_fail.w" <<'EOF4'
use std.collections

fn main -> i32:
    var counts: HashMap[str, i32] = HashMap.new()
    increment(counts, 1)
    0
EOF4
expect_check_fail "$tmpdir/hashmap_convenience_bad_wrapper_key_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase3 HashMap convenience tests: $failures failure(s)"
  exit 1
fi

echo "phase3 HashMap convenience tests: PASS"
