#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 try-lowering tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(try-lowering-run) $file"
  else
    echo "FAIL(try-lowering-run) $file"
    failures=$((failures + 1))
  fi
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(try-lowering-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(try-lowering-run-fail) $file"
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(try-lowering-check-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(try-lowering-check-fail) $file"
  fi
}

cat >"$tmpdir/result_try_propagation_ok.w" <<'EOF1'
error ParseError = Bad

fn parse(flag: bool) -> Result[i32, ParseError] =
    if flag then Ok(9) else Err(Bad)

fn doubled(flag: bool) -> Result[i32, ParseError] =
    let v = parse(flag)?
    v * 2

fn main() -> i32 =
    let a = doubled(true)
    let b = doubled(false)
    if a.is_ok() and b.is_err() and (a ?? 0) == 18 then 0 else 1
EOF1
expect_run_pass "$tmpdir/result_try_propagation_ok.w"

cat >"$tmpdir/option_try_propagation_ok.w" <<'EOF2'
fn find(flag: bool) -> Option[i32] =
    if flag then Some(7) else None

fn inc(flag: bool) -> Option[i32] =
    let v = find(flag)?
    Some(v + 1)

fn main() -> i32 =
    let a = inc(true)
    let b = inc(false)
    if a.is_some() and b.is_none() and (a ?? 0) == 8 then 0 else 1
EOF2
expect_run_pass "$tmpdir/option_try_propagation_ok.w"

cat >"$tmpdir/result_try_error_from_conversion_ok.w" <<'EOF3'
error IoError = Disk
error AppError from IoError

fn read() -> Result[i32, IoError] = Err(Disk)

fn load() -> Result[i32, AppError] =
    let _x = read()?
    1

fn main() -> i32 =
    let err = load().err().unwrap()
    if err.as_Io().is_some() then 0 else 1
EOF3
expect_run_pass "$tmpdir/result_try_error_from_conversion_ok.w"

cat >"$tmpdir/try_non_container_check_fail.w" <<'EOF4'
fn main() -> i32 =
    let one = 1
    let x = one?
    x
EOF4
expect_check_fail "$tmpdir/try_non_container_check_fail.w"

cat >"$tmpdir/try_result_in_non_result_return_fail.w" <<'EOF5'
fn source() -> Result[i32, i32] = Err(7)

fn wrong() -> i32 =
    let x = source()?
    x

fn main() -> i32 = wrong()
EOF5
expect_run_fail "$tmpdir/try_result_in_non_result_return_fail.w"

cat >"$tmpdir/try_option_in_result_return_fail.w" <<'EOF6'
fn source() -> Option[i32] = None

fn wrong() -> Result[i32, i32] =
    let x = source()?
    Ok(x)

fn main() -> i32 =
    if wrong().is_err() then 0 else 1
EOF6
expect_run_fail "$tmpdir/try_option_in_result_return_fail.w"

cat >"$tmpdir/try_result_in_option_return_fail.w" <<'EOF7'
fn source() -> Result[i32, i32] = Err(3)

fn wrong() -> Option[i32] =
    let x = source()?
    Some(x)

fn main() -> i32 =
    if wrong().is_none() then 0 else 1
EOF7
expect_run_fail "$tmpdir/try_result_in_option_return_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 try-lowering tests: $failures failure(s)"
  exit 1
fi

echo "phase2 try-lowering tests: PASS"
