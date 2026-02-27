#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase3 std.fmt tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(std-fmt-check) $file"
  else
    echo "FAIL(std-fmt-check) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(std-fmt-run) $file"
  else
    echo "FAIL(std-fmt-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_output() {
  local file="$1"
  local expected="$2"
  local out
  if ! out=$("$WITH_BIN" run "$file" 2>"$tmpdir/stderr.$$"); then
    echo "FAIL(std-fmt-output-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
    rm -f "$tmpdir/stderr.$$"
    return
  fi
  rm -f "$tmpdir/stderr.$$"
  if [[ "$out" != "$expected" ]]; then
    echo "FAIL(std-fmt-output) $file"
    echo "--- expected ---"
    printf '%s\n' "$expected"
    echo "--- actual ---"
    printf '%s\n' "$out"
    failures=$((failures + 1))
    return
  fi
  echo "PASS(std-fmt-output) $file"
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(std-fmt-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(std-fmt-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_pass "lib/std/fmt.w"

cat >"$tmpdir/std_fmt_wrappers_ok.w" <<'EOF1'
use std.mem
use std.fmt

fn main -> i32:
    let int_buf = alloc_zeroed(64, 1)
    let hex_buf = alloc_zeroed(64, 1)
    let float_buf = alloc_zeroed(64, 1)
    assert(int_buf != 0)
    assert(hex_buf != 0)
    assert(float_buf != 0)

    let int_len = fmt_int(int_buf, 64, 0 - 42)
    let hex_len = fmt_hex(hex_buf, 64, 255)
    let float_len = fmt_float(float_buf, 64, 3.5)
    assert(int_len == 3)
    assert(hex_len == 4)
    assert(float_len > 0)

    println(int_buf)
    println(hex_buf)
    println(float_buf)

    free_mem(int_buf)
    free_mem(hex_buf)
    free_mem(float_buf)
    0
EOF1
expect_run_output "$tmpdir/std_fmt_wrappers_ok.w" $'-42\n0xff\n3.500000'

cat >"$tmpdir/std_fmt_truncate_ok.w" <<'EOF2'
use std.mem
use std.fmt

fn main -> i32:
    let buf = alloc_zeroed(2, 1)
    assert(buf != 0)
    let written = fmt_int(buf, 2, 1234)
    assert(written == 4)
    println(buf)
    free_mem(buf)
    0
EOF2
expect_run_output "$tmpdir/std_fmt_truncate_ok.w" $'1'

cat >"$tmpdir/std_fmt_interpolation_backend_ok.w" <<'EOF3'
type Point = { x: i32, y: i32 }

fn main -> i32:
    let name = "with"
    let x = 41
    let p = Point { x: 7, y: 9 }
    let pi = 3.14159

    println("hello {name}")
    println("sum={x + 1}")
    println("coords=({p.x},{p.y})")
    println("scaled={(x + 1) * 2}")
    println("pi={pi:.2}")
EOF3
expect_run_output "$tmpdir/std_fmt_interpolation_backend_ok.w" $'hello with\nsum=42\ncoords=(7,9)\nscaled=84\npi=3.14'

expect_run_output "bootstrap/test/cases/string_interp.w" $'Hello, World!\nx = 42\nsum = 43'
expect_run_pass "bootstrap/test/cases/string_interp_expr.w"
expect_run_pass "bootstrap/test/cases/string_interp_multi.w"

cat >"$tmpdir/std_fmt_bad_ptr_arg_fail.w" <<'EOF4'
use std.fmt

fn main -> i32:
    let _n = fmt_int(true, 64, 1)
EOF4
expect_check_fail "$tmpdir/std_fmt_bad_ptr_arg_fail.w"

cat >"$tmpdir/std_fmt_bad_size_arg_fail.w" <<'EOF5'
use std.mem
use std.fmt

fn main -> i32:
    let buf = alloc_zeroed(8, 1)
    let _n = fmt_hex(buf, false, 255)
    free_mem(buf)
    0
EOF5
expect_check_fail "$tmpdir/std_fmt_bad_size_arg_fail.w"

cat >"$tmpdir/std_fmt_bad_value_arg_fail.w" <<'EOF6'
use std.mem
use std.fmt

fn main -> i32:
    let buf = alloc_zeroed(8, 1)
    let _n = fmt_float(buf, 8)
    free_mem(buf)
    0
EOF6
expect_check_fail "$tmpdir/std_fmt_bad_value_arg_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase3 std.fmt tests: $failures failure(s)"
  exit 1
fi

echo "phase3 std.fmt tests: PASS"
