#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase3 std.fs tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(std-fs-check) $file"
  else
    echo "FAIL(std-fs-check) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(std-fs-run) $file"
  else
    echo "FAIL(std-fs-run) $file"
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
    echo "FAIL(std-fs-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
    rm -f "$tmpdir/stderr.$$"
    return
  fi
  rm -f "$tmpdir/stderr.$$"
  if [[ "$out" != "$expected" ]]; then
    echo "FAIL(std-fs-output) $file"
    echo "--- expected ---"
    printf '%s\n' "$expected"
    echo "--- actual ---"
    printf '%s\n' "$out"
    failures=$((failures + 1))
    return
  fi
  echo "PASS(std-fs-output) $file"
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(std-fs-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(std-fs-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_pass "lib/std/fs.w"

expect_run_pass "test/cases/std_fs_io.w"
expect_run_pass "test/cases/p3_std_fs_io.w"

cat >"$tmpdir/std_fs_roundtrip_and_dirs_ok.w" <<'EOF1'
use std.fs

fn main() -> i32 =
    let dir = "/tmp/with_std_fs_phase3_dir"
    let file_a = "/tmp/with_std_fs_phase3_dir/a.txt"
    let file_b = "/tmp/with_std_fs_phase3_dir/b.txt"

    // Best-effort cleanup from any prior run.
    remove_file(file_a)
    remove_file(file_b)
    remove_dir(dir)

    assert(create_dir(dir) == 0)
    assert(file_exists(dir))

    assert(write_file(file_a, "hello fs") == 0)
    assert(file_exists(file_a))
    let text_a = read_file(file_a)
    assert(text_a == "hello fs")

    assert(rename_file(file_a, file_b) == 0)
    assert(not file_exists(file_a))
    assert(file_exists(file_b))
    let text_b = read_file(file_b)
    assert(text_b == "hello fs")

    assert(remove_file(file_b) == 0)
    assert(not file_exists(file_b))
    assert(remove_dir(dir) == 0)
    assert(not file_exists(dir))

    println("fs-ok")
    0
EOF1
expect_run_output "$tmpdir/std_fs_roundtrip_and_dirs_ok.w" $'fs-ok'

cat >"$tmpdir/std_fs_missing_read_ok.w" <<'EOF2'
use std.fs

fn main() -> i32 =
    let missing = read_file("/tmp/with_std_fs_missing_938475938475.txt")
    println(missing.len())
    0
EOF2
expect_run_output "$tmpdir/std_fs_missing_read_ok.w" $'0'

cat >"$tmpdir/std_fs_create_dir_twice_ok.w" <<'EOF3'
use std.fs

fn main() -> i32 =
    let dir = "/tmp/with_std_fs_phase3_dir_twice"
    remove_dir(dir)
    assert(create_dir(dir) == 0)
    let second = create_dir(dir)
    assert(second != 0)
    assert(remove_dir(dir) == 0)
    println("dir-fail-ok")
    0
EOF3
expect_run_output "$tmpdir/std_fs_create_dir_twice_ok.w" $'dir-fail-ok'

cat >"$tmpdir/std_fs_bad_write_arg_fail.w" <<'EOF4'
use std.fs

fn main() -> i32 =
    let _rc = write_file(1, "abc")
    0
EOF4
expect_check_fail "$tmpdir/std_fs_bad_write_arg_fail.w"

cat >"$tmpdir/std_fs_bad_rename_arity_fail.w" <<'EOF5'
use std.fs

fn main() -> i32 =
    let _rc = rename_file("/tmp/a")
    0
EOF5
expect_check_fail "$tmpdir/std_fs_bad_rename_arity_fail.w"

cat >"$tmpdir/std_fs_bad_create_arg_fail.w" <<'EOF6'
use std.fs

fn main() -> i32 =
    let _rc = create_dir(true)
    0
EOF6
expect_check_fail "$tmpdir/std_fs_bad_create_arg_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase3 std.fs tests: $failures failure(s)"
  exit 1
fi

echo "phase3 std.fs tests: PASS"
