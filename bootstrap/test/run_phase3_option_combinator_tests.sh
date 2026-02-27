#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase3 Option combinator tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(option-check) $file"
  else
    echo "FAIL(option-check) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(option-run) $file"
  else
    echo "FAIL(option-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(option-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(option-run-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_pass "lib/std/option.w"

expect_run_pass "bootstrap/test/cases/option_map.w"
expect_run_pass "bootstrap/test/cases/option_combinators.w"
expect_run_pass "bootstrap/test/cases/option_chain_adv.w"
expect_run_pass "bootstrap/test/cases/option_unwrap.w"

cat >"$tmpdir/option_combinator_extended_ok.w" <<'EOF1'
fn plus_one(x: i32) -> i32: x + 1
fn half_if_even(x: i32) -> ?i32: if x % 2 == 0 then Some(x / 2) else None
fn fallback -> ?i32: Some(9)
fn is_even(x: i32) -> bool: x % 2 == 0

fn main -> i32:
    let a: ?i32 = Some(1)
    let mapped = a.map(plus_one)
    assert(mapped.unwrap_or(0) == 2)

    let chained = Some(8).and_then(half_if_even)
    assert(chained.unwrap_or(0) == 4)

    let or_else_val = None.or_else(fallback)
    assert(or_else_val.unwrap_or(0) == 9)

    let filtered = Some(6).filter(is_even)
    assert(filtered.unwrap_or(0) == 6)

    let zipped: ?(i32, i32) = Some(3).zip(Some(4))
    assert(zipped.is_some())

    let cloned = Some(7).cloned()
    assert(cloned.unwrap_or(0) == 7)

    let nested: ?(?i32) = Some(Some(5))
    let flat: ?i32 = nested.flatten()
    assert(flat.unwrap_or(0) == 5)

    let tr_src: ?Result[i32, str] = Some(Ok(1))
    let tr = tr_src.transpose()
    assert(tr.is_ok())
EOF1
expect_run_pass "$tmpdir/option_combinator_extended_ok.w"

cat >"$tmpdir/option_or_else_bad_arg_fail.w" <<'EOF2'
fn main -> i32:
    let a: ?i32 = None
    let _b = a.or_else(1)
EOF2
expect_run_fail "$tmpdir/option_or_else_bad_arg_fail.w"

cat >"$tmpdir/option_zip_bad_arity_fail.w" <<'EOF3'
fn main -> i32:
    let a: ?i32 = Some(1)
    let _z = a.zip()
EOF3
expect_run_fail "$tmpdir/option_zip_bad_arity_fail.w"

cat >"$tmpdir/option_flatten_bad_type_fail.w" <<'EOF4'
fn main -> i32:
    let a: ?i32 = Some(1)
    let _f = a.flatten()
EOF4
expect_run_fail "$tmpdir/option_flatten_bad_type_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase3 Option combinator tests: $failures failure(s)"
  exit 1
fi

echo "phase3 Option combinator tests: PASS"
