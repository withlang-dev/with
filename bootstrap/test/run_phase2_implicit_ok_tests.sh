#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 implicit-ok tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(implicit-ok-run) $file"
  else
    echo "FAIL(implicit-ok-run) $file"
    failures=$((failures + 1))
  fi
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(implicit-ok-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(implicit-ok-run-fail) $file"
  fi
}

cat >"$tmpdir/implicit_ok_value_tail_ok.w" <<'EOF1'
fn get -> Result[i32, i32]:
    42

fn main -> i32:
    if (get() ?? -1) == 42 then 0 else 1
EOF1
expect_run_pass "$tmpdir/implicit_ok_value_tail_ok.w"

cat >"$tmpdir/implicit_ok_with_try_ok.w" <<'EOF2'
error ParseError = Bad

fn parse(flag: bool) -> Result[i32, ParseError]:
    if flag then Ok(5) else Err(Bad)

fn compute(flag: bool) -> Result[i32, ParseError]:
    let v = parse(flag)?
    v + 3

fn main -> i32:
    let ok = compute(true)
    let err = compute(false)
    if (ok ?? -1) == 8 and err.is_err() then 0 else 1
EOF2
expect_run_pass "$tmpdir/implicit_ok_with_try_ok.w"

cat >"$tmpdir/implicit_ok_explicit_return_ok.w" <<'EOF3'
fn f -> Result[i32, i32]:
    return 7

fn main -> i32:
    let r = f()
    if r.is_ok() and (r ?? -1) == 7 then 0 else 1
EOF3
expect_run_pass "$tmpdir/implicit_ok_explicit_return_ok.w"

cat >"$tmpdir/implicit_ok_passthrough_result_ok.w" <<'EOF4'
fn source(flag: bool) -> Result[i32, i32]:
    if flag then Ok(9) else Err(2)

fn wrap(flag: bool) -> Result[i32, i32]:
    source(flag)

fn main -> i32:
    let a = wrap(true)
    let b = wrap(false)
    if a.is_ok() and b.is_err() and (a ?? -1) == 9 then 0 else 1
EOF4
expect_run_pass "$tmpdir/implicit_ok_passthrough_result_ok.w"

cat >"$tmpdir/implicit_ok_result_unit_empty_tail_ok.w" <<'EOF5'
fn touch -> Result[Unit, i32]:
    let x = 1
    let y = x + 2

fn main -> i32:
    let r = touch()
    if r.is_ok() then 0 else 1
EOF5
expect_run_pass "$tmpdir/implicit_ok_result_unit_empty_tail_ok.w"

cat >"$tmpdir/implicit_ok_non_unit_empty_tail_fail.w" <<'EOF6'
fn bad -> Result[i32, i32]:
    let x = 1

fn main -> i32: 0
EOF6
expect_run_fail "$tmpdir/implicit_ok_non_unit_empty_tail_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 implicit-ok tests: $failures failure(s)"
  exit 1
fi

echo "phase2 implicit-ok tests: PASS"
