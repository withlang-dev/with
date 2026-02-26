#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase3 collection combinator tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(collection-check) $file"
  else
    echo "FAIL(collection-check) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(collection-run) $file"
  else
    echo "FAIL(collection-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(collection-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(collection-run-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_pass "lib/std/collections.w"
expect_run_pass "test/cases/sequence_traverse.w"
expect_run_pass "test/cases/import_std_collections.w"

cat >"$tmpdir/sequence_non_wrapper_fail.w" <<'EOF1'
fn main() -> i32 =
    var xs: Vec[i32] = Vec.new()
    xs.push(1)
    let _r = xs.sequence()
    0
EOF1
expect_run_fail "$tmpdir/sequence_non_wrapper_fail.w"

cat >"$tmpdir/traverse_non_wrapper_fail.w" <<'EOF2'
fn plus_one(x: i32) -> i32 =
    x + 1

fn main() -> i32 =
    var xs: Vec[i32] = Vec.new()
    xs.push(1)
    let _r = xs.traverse(plus_one)
    0
EOF2
expect_run_fail "$tmpdir/traverse_non_wrapper_fail.w"

cat >"$tmpdir/traverse_missing_arg_fail.w" <<'EOF3'
fn main() -> i32 =
    var xs: Vec[i32] = Vec.new()
    let _r = xs.traverse()
    0
EOF3
expect_run_fail "$tmpdir/traverse_missing_arg_fail.w"

cat >"$tmpdir/sequence_unexpected_arg_fail.w" <<'EOF4'
fn main() -> i32 =
    var xs: Vec[?i32] = Vec.new()
    let _r = xs.sequence(1)
    0
EOF4
expect_run_fail "$tmpdir/sequence_unexpected_arg_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase3 collection combinator tests: $failures failure(s)"
  exit 1
fi

echo "phase3 collection combinator tests: PASS"
