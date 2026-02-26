#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase3 std.io tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(std-io-check) $file"
  else
    echo "FAIL(std-io-check) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(std-io-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(std-io-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_output() {
  local file="$1"
  local expected="$2"
  local out
  if ! out=$("$WITH_BIN" run "$file" 2>"$tmpdir/stderr.$$"); then
    echo "FAIL(std-io-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
    rm -f "$tmpdir/stderr.$$"
    return
  fi
  rm -f "$tmpdir/stderr.$$"
  if [[ "$out" != "$expected" ]]; then
    echo "FAIL(std-io-output) $file"
    echo "--- expected ---"
    printf '%s\n' "$expected"
    echo "--- actual ---"
    printf '%s\n' "$out"
    failures=$((failures + 1))
    return
  fi
  echo "PASS(std-io-output) $file"
}

expect_check_pass "lib/std/io.w"

expect_run_output "test/cases/stdlib_io.w" $'hello world\n42\n3.140000\nall stdlib io tests passed'

cat >"$tmpdir/std_io_file_roundtrip_ok.w" <<'EOF1'
use std.io
use std.mem

fn main -> i32:
    let path = "/tmp/with_std_io_roundtrip.txt"

    let out = file_open(path, "w")
    assert(out != 0)
    assert(file_write(out, "abc") >= 0)
    assert(file_close(out) == 0)

    let inp = file_open(path, "r")
    assert(inp != 0)
    let buf = alloc_zeroed(8, 1)
    assert(buf != 0)
    let n = file_read(inp, buf, 3)
    assert(n == 3)
    assert(file_close(inp) == 0)

    println(buf)
    free_mem(buf)
    0
EOF1
expect_run_output "$tmpdir/std_io_file_roundtrip_ok.w" $'abc'

cat >"$tmpdir/std_io_file_missing_ok.w" <<'EOF2'
use std.io

fn main -> i32:
    let inp = file_open("/tmp/with_std_io_missing_938475938475.txt", "r")
    if inp == 0 then
        println("missing")
    else
        file_close(inp)
EOF2
expect_run_output "$tmpdir/std_io_file_missing_ok.w" $'missing'

cat >"$tmpdir/std_io_bad_open_arg_fail.w" <<'EOF3'
use std.io

fn main -> i32:
    let _f = file_open(123, "r")
EOF3
expect_check_fail "$tmpdir/std_io_bad_open_arg_fail.w"

cat >"$tmpdir/std_io_bad_close_arg_fail.w" <<'EOF4'
use std.io

fn main -> i32:
    let _rc = file_close(1)
EOF4
expect_check_fail "$tmpdir/std_io_bad_close_arg_fail.w"

cat >"$tmpdir/std_io_bad_read_arity_fail.w" <<'EOF5'
use std.io
use std.mem

fn main -> i32:
    let inp = file_open("/tmp/with_std_io_missing_938475938475.txt", "r")
    let buf = alloc_zeroed(8, 1)
    let _n = file_read(inp, buf)
EOF5
expect_check_fail "$tmpdir/std_io_bad_read_arity_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase3 std.io tests: $failures failure(s)"
  exit 1
fi

echo "phase3 std.io tests: PASS"
