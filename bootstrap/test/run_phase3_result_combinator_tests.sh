#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase3 Result combinator tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(result-check) $file"
  else
    echo "FAIL(result-check) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(result-run) $file"
  else
    echo "FAIL(result-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(result-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(result-run-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_pass "lib/std/result.w"

expect_run_pass "bootstrap/test/cases/result_map.w"
expect_run_pass "bootstrap/test/cases/result_and_then.w"
expect_run_pass "bootstrap/test/cases/result_combinators.w"
expect_run_pass "bootstrap/test/cases/import_std_result.w"

cat >"$tmpdir/result_combinator_extended_ok.w" <<'EOF1'
fn plus_one(x: i32) -> Result[i32, i32]:
    Ok(x + 1)

fn fail_if_odd(x: i32) -> Result[i32, i32]:
    if x % 2 == 1 then Err(77) else Ok(x)

fn widen_err(e: i32) -> Result[i32, i64]:
    Err(1000 + e)

fn main -> i32:
    let a: Result[i32, i32] = Ok(10)
    let b = a.and_then(plus_one)
    assert(b.unwrap_or(0) == 11)

    // Ensure existing Err payload is preserved through and_then.
    let c: Result[i32, i32] = Err(5)
    let d = c.and_then(plus_one)
    assert(d.is_err())
    assert(d.err().unwrap_or(0) == 5)

    let e = b.and_then(fail_if_odd)
    assert(e.is_err())

    let f = e.or_else(widen_err)
    assert(f.is_err())

    let g: Result[?i32, str] = Ok(Some(3))
    let gt = g.transpose()
    assert(gt.is_some())

    let h: Result[?i32, str] = Ok(None)
    let ht = h.transpose()
    assert(ht.is_none())

    let i: Result[?i32, str] = Err("bad")
    let it = i.transpose()
    assert(it.is_some())
EOF1
expect_run_pass "$tmpdir/result_combinator_extended_ok.w"

cat >"$tmpdir/result_or_else_bad_ok_type_fail.w" <<'EOF2'
fn bad(e: i32) -> Result[str, i32]:
    let _x = e
    Ok("x")

fn main -> i32:
    let a: Result[i32, i32] = Err(1)
    let _b = a.or_else(bad)
EOF2
expect_run_fail "$tmpdir/result_or_else_bad_ok_type_fail.w"

cat >"$tmpdir/result_and_then_bad_return_fail.w" <<'EOF3'
fn bad(x: i32) -> ?i32:
    Some(x)

fn main -> i32:
    let a: Result[i32, i32] = Ok(1)
    let _b = a.and_then(bad)
EOF3
expect_run_fail "$tmpdir/result_and_then_bad_return_fail.w"

cat >"$tmpdir/result_transpose_bad_receiver_fail.w" <<'EOF4'
fn main -> i32:
    let a: Result[i32, i32] = Ok(1)
    let _b = a.transpose()
EOF4
expect_run_fail "$tmpdir/result_transpose_bad_receiver_fail.w"

cat >"$tmpdir/result_map_err_on_option_fail.w" <<'EOF5'
fn id(x: i32) -> i32:
    x

fn main -> i32:
    let a: ?i32 = Some(1)
    let _b = a.map_err(id)
EOF5
expect_run_fail "$tmpdir/result_map_err_on_option_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase3 Result combinator tests: $failures failure(s)"
  exit 1
fi

echo "phase3 Result combinator tests: PASS"
