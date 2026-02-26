#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase6 comptime_error tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(comptime-error-run) $file"
  else
    echo "FAIL(comptime-error-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_fail_msg() {
  local file="$1"
  local msg="$2"
  local stderr_file="$tmpdir/stderr.err.$$"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$stderr_file"; then
    echo "FAIL(comptime-error-run-fail) $file"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(comptime-error-run-fail) $file"
    else
      echo "FAIL(comptime-error-run-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$stderr_file"
}

# Positive baseline: untaken branch does not trigger comptime_error.
expect_run_pass "test/cases/comptime_error.w"

# Negative: direct comptime_error call fails compilation/run.
cat >"$tmpdir/comptime_error_direct_fail.w" <<'EOF1'
fn main -> i32:
    comptime_error("boom")
EOF1
expect_run_fail_msg "$tmpdir/comptime_error_direct_fail.w" "comptime_error"

# Negative: taken comptime-if branch triggers comptime_error.
cat >"$tmpdir/comptime_error_taken_branch_fail.w" <<'EOF2'
fn main -> i32:
    comptime if 2 > 1:
        comptime_error("taken")
    0
EOF2
expect_run_fail_msg "$tmpdir/comptime_error_taken_branch_fail.w" "comptime_error"

if [[ "$failures" -ne 0 ]]; then
  echo "phase6 comptime_error tests: $failures failure(s)"
  exit 1
fi

echo "phase6 comptime_error tests: PASS"
