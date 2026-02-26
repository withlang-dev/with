#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase6 comptime-fn constraint tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(comptime-fn-constraints-run) $file"
  else
    echo "FAIL(comptime-fn-constraints-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_fail_msg() {
  local file="$1"
  local msg="$2"
  local stderr_file="$tmpdir/stderr.err.$$"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$stderr_file"; then
    echo "FAIL(comptime-fn-constraints-check-fail) $file"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(comptime-fn-constraints-check-fail) $file"
    else
      echo "FAIL(comptime-fn-constraints-check-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$stderr_file"
}

# Positive: deterministic/pure comptime fn remains valid.
cat >"$tmpdir/comptime_fn_pure_ok.w" <<'EOF1'
comptime fn eval(x: i32) -> i32:
    let mut s = 0
    for i in [1, 2, 3, 4]:
        if i <= x:
            s = s + i
    s

fn main -> i32:
    assert(eval(3) == 6)
EOF1
expect_run_pass "$tmpdir/comptime_fn_pure_ok.w"

# Positive baseline from existing comptime suite.
expect_run_pass "test/cases/comptime.w"

# Non-happy-path: I/O in comptime fn is denied.
cat >"$tmpdir/comptime_fn_io_fail.w" <<'EOF2'
comptime fn noisy -> i32:
    println(1)

fn main -> i32:
    noisy()
EOF2
expect_check_fail_msg "$tmpdir/comptime_fn_io_fail.w" "comptime fn cannot perform I/O"

# Non-happy-path: extern/FFI call in comptime fn is denied.
cat >"$tmpdir/comptime_fn_extern_fail.w" <<'EOF3'
use c_import("#include <stdio.h>")

comptime fn bad -> i32:
    puts(c"x")

fn main -> i32:
    bad()
EOF3
expect_check_fail_msg "$tmpdir/comptime_fn_extern_fail.w" "comptime fn cannot call extern functions"

if [[ "$failures" -ne 0 ]]; then
  echo "phase6 comptime-fn constraint tests: $failures failure(s)"
  exit 1
fi

echo "phase6 comptime-fn constraint tests: PASS"
