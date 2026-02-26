#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase4 std.signal tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(std-signal-run) $file"
  else
    echo "FAIL(std-signal-run) $file"
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
    echo "FAIL(std-signal-check-fail) $file"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(std-signal-check-fail) $file"
    else
      echo "FAIL(std-signal-check-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$stderr_file"
}

expect_run_pass "test/cases/import_std_signal.w"

cat >"$tmpdir/std_signal_constants_and_raise0_ok.w" <<'EOF1'
use std.signal

fn main -> i32:
    assert(sigint() == 2)
    assert(sigterm() == 15)
    assert(sigkill() == 9)
    assert(raise_signal(0) == 0)
EOF1
expect_run_pass "$tmpdir/std_signal_constants_and_raise0_ok.w"

cat >"$tmpdir/std_signal_raise_arity_fail.w" <<'EOF2'
use std.signal

fn main -> i32:
    let _ = raise_signal()
EOF2
expect_check_fail_msg "$tmpdir/std_signal_raise_arity_fail.w" "expects 1 argument(s)"

cat >"$tmpdir/std_signal_sigint_arity_fail.w" <<'EOF3'
use std.signal

fn main -> i32:
    let _ = sigint(1)
EOF3
expect_check_fail_msg "$tmpdir/std_signal_sigint_arity_fail.w" "expects 0 argument(s)"

cat >"$tmpdir/std_signal_raise_type_fail.w" <<'EOF4'
use std.signal

fn main -> i32:
    let _ = raise_signal("bad")
EOF4
expect_check_fail_msg "$tmpdir/std_signal_raise_type_fail.w" "wrong type"

if [[ "$failures" -ne 0 ]]; then
  echo "phase4 std.signal tests: $failures failure(s)"
  exit 1
fi

echo "phase4 std.signal tests: PASS"
