#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for c_import link tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/ext_add.c" <<'C1'
int ext_add(int a, int b) { return a + b + 100; }
C1

cat >"$tmpdir/ext_mul.c" <<'C2'
int ext_mul(int a, int b) { return a * b; }
C2

cc -c "$tmpdir/ext_add.c" -o "$tmpdir/ext_add.o"
ar rcs "$tmpdir/libextadd.a" "$tmpdir/ext_add.o"
cc -c "$tmpdir/ext_mul.c" -o "$tmpdir/ext_mul.o"
ar rcs "$tmpdir/libextmul.a" "$tmpdir/ext_mul.o"

failures=0

expect_run_pass() {
  local file="$1"
  if LIBRARY_PATH="$tmpdir${LIBRARY_PATH:+:$LIBRARY_PATH}" "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(c_import-link-run) $file"
  else
    echo "FAIL(c_import-link-run) $file"
    failures=$((failures + 1))
  fi
}

expect_run_fail() {
  local file="$1"
  if LIBRARY_PATH="$tmpdir${LIBRARY_PATH:+:$LIBRARY_PATH}" "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(c_import-link-negative) $file"
    failures=$((failures + 1))
  else
    echo "PASS(c_import-link-negative) $file"
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(c_import-link-parse-negative) $file"
    failures=$((failures + 1))
  else
    echo "PASS(c_import-link-parse-negative) $file"
  fi
}

cat >"$tmpdir/c_import_link_ok.w" <<'EOF1'
use c_import("int ext_add(int, int);", link: "extadd")

fn main -> i32:
    if ext_add(2, 3) == 105 then 0 else 1
EOF1
expect_run_pass "$tmpdir/c_import_link_ok.w"

cat >"$tmpdir/c_import_link_missing.w" <<'EOF2'
use c_import("int ext_add(int, int);")

fn main -> i32:
    if ext_add(2, 3) == 105 then 0 else 1
EOF2
expect_run_fail "$tmpdir/c_import_link_missing.w"

cat >"$tmpdir/c_import_link_multi.w" <<'EOF3'
use c_import("int ext_add(int, int); int ext_mul(int, int);", link: "extadd", "extmul")

fn main -> i32:
    let a = ext_add(1, 2)
    let b = ext_mul(3, 4)
    if a == 103 and b == 12 then 0 else 1
EOF3
expect_run_pass "$tmpdir/c_import_link_multi.w"

cat >"$tmpdir/c_import_link_bad_arg.w" <<'EOF4'
use c_import("int ext_add(int, int);", libs: "extadd")

fn main -> i32:
    0
EOF4
expect_check_fail "$tmpdir/c_import_link_bad_arg.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase0 c_import link tests: $failures failure(s)"
  exit 1
fi

echo "phase0 c_import link tests: PASS"
