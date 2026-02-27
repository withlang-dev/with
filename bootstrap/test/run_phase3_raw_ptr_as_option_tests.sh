#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase3 raw pointer as_option tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(raw-ptr-run) $file"
  else
    echo "FAIL(raw-ptr-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(raw-ptr-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(raw-ptr-run-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_pass "bootstrap/test/cases/raw_ptr_option.w"
expect_run_pass "bootstrap/test/cases/p3_raw_ptr_as_option.w"

cat >"$tmpdir/raw_ptr_as_option_extra_ok.w" <<'EOF1'
use c_import("#include <stdlib.h>")

fn main -> i32:
    let p1 = malloc(8)
    let o1 = p1.as_option()
    assert(o1.is_some())
    free(p1)

    let p2 = malloc(16)
    let o2 = p2.as_option()
    assert(o2.is_some())
    free(p2)
    0
EOF1
expect_run_pass "$tmpdir/raw_ptr_as_option_extra_ok.w"

cat >"$tmpdir/raw_ptr_as_option_non_ptr_fail.w" <<'EOF2'
fn main -> i32:
    let x = 123
    let _o = x.as_option()
EOF2
expect_run_fail "$tmpdir/raw_ptr_as_option_non_ptr_fail.w"

cat >"$tmpdir/raw_ptr_as_option_arity_fail.w" <<'EOF3'
use c_import("#include <stdlib.h>")

fn main -> i32:
    let p = malloc(8)
    let _o = p.as_option(1)
    free(p)
    0
EOF3
expect_run_fail "$tmpdir/raw_ptr_as_option_arity_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase3 raw pointer as_option tests: $failures failure(s)"
  exit 1
fi

echo "phase3 raw pointer as_option tests: PASS"
