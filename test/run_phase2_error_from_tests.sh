#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 error-from tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(error-from-run) $file"
  else
    echo "FAIL(error-from-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(error-from-check-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(error-from-check-fail) $file"
  fi
}

cat >"$tmpdir/error_from_single_ok.w" <<'EOF1'
error IoError = Disk
error AppError from IoError

fn f() -> Result[i32, IoError] = Err(Disk)

fn g() -> Result[i32, AppError] =
    let x = f()?
    x

fn main() -> i32 =
    let app = g().err().unwrap()
    let io = app.as_Io()
    if io.is_some() and io.unwrap().is_Disk() then 0 else 1
EOF1
expect_run_pass "$tmpdir/error_from_single_ok.w"

cat >"$tmpdir/error_from_multi_ok.w" <<'EOF2'
error IoError = Disk
error ParseError = Bad
error AppError from IoError, ParseError

fn io_fail() -> Result[i32, IoError] = Err(Disk)
fn parse_fail() -> Result[i32, ParseError] = Err(Bad)

fn g_io() -> Result[i32, AppError] =
    let _x = io_fail()?
    1

fn g_parse() -> Result[i32, AppError] =
    let _x = parse_fail()?
    2

fn main() -> i32 =
    let e1 = g_io().err().unwrap()
    let e2 = g_parse().err().unwrap()
    let a = e1.as_Io()
    let b = e2.as_Parse()
    if a.is_some() and b.is_some() and a.unwrap().is_Disk() and b.unwrap().is_Bad() then 0 else 1
EOF2
expect_run_pass "$tmpdir/error_from_multi_ok.w"

cat >"$tmpdir/error_from_unknown_source_fail.w" <<'EOF3'
error AppError from MissingError

fn main() -> i32 = 0
EOF3
expect_check_fail "$tmpdir/error_from_unknown_source_fail.w"

cat >"$tmpdir/error_from_trailing_comma_fail.w" <<'EOF4'
error IoError = Disk
error AppError from IoError,

fn main() -> i32 = 0
EOF4
expect_check_fail "$tmpdir/error_from_trailing_comma_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 error-from tests: $failures failure(s)"
  exit 1
fi

echo "phase2 error-from tests: PASS"
