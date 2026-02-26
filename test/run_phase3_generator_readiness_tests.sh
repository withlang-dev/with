#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase3 generator-readiness tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(generator-run) $file"
  else
    echo "FAIL(generator-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(generator-check-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(generator-check-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_pass "test/cases/generator.w"
expect_run_pass "test/cases/gen_params.w"
expect_run_pass "test/cases/gen_multi_yield.w"
expect_run_pass "test/cases/gen_fib.w"
expect_run_pass "test/cases/generator_stdlib_ready.w"

cat >"$tmpdir/generator_type_mismatch_fail.w" <<'EOF1'
gen fn bad_yield_type -> i32:
    yield "oops"

fn main -> i32:
    var it = bad_yield_type()
    for _x in it:
        ()
    0
EOF1
expect_check_fail "$tmpdir/generator_type_mismatch_fail.w"

cat >"$tmpdir/generator_ref_across_yield_fail.w" <<'EOF2'
gen fn bad_ref_gen -> &str:
    let s = "hello"
    yield &s

fn main -> i32:
    var it = bad_ref_gen()
    for _x in it:
        ()
    0
EOF2
expect_check_fail "$tmpdir/generator_ref_across_yield_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase3 generator readiness tests: $failures failure(s)"
  exit 1
fi

echo "phase3 generator readiness tests: PASS"
