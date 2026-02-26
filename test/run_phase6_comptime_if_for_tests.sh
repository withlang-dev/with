#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase6 comptime-if/for tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(comptime-if-for-run) $file"
  else
    echo "FAIL(comptime-if-for-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(comptime-if-for-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(comptime-if-for-run-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

# Existing positive coverage.
expect_run_pass "test/cases/comptime_if.w"
expect_run_pass "test/cases/comptime_for.w"
expect_run_pass "test/cases/comptime.w"
expect_run_pass "test/cases/comptime_arith.w"
expect_run_pass "test/cases/comptime_block.w"

# Positive: compositional comptime-if + comptime-for.
cat >"$tmpdir/comptime_if_for_combo_ok.w" <<'EOF1'
fn sum_scaled -> i32:
    var total = 0
    let scale = comptime if 3 > 1 then 2 else 5
    comptime for i in [1, 2, 3]:
        total = total + i * scale
    total

fn main -> i32:
    assert(sum_scaled() == 12)
EOF1
expect_run_pass "$tmpdir/comptime_if_for_combo_ok.w"

# Non-happy-path: comptime-for iterable must still be valid iterable expression.
cat >"$tmpdir/comptime_for_non_iterable_fail.w" <<'EOF2'
fn main -> i32:
    comptime for i in 1:
        let _ = i
EOF2
expect_run_fail "$tmpdir/comptime_for_non_iterable_fail.w"

# Non-happy-path: malformed comptime-if expression should fail.
cat >"$tmpdir/comptime_if_missing_else_fail.w" <<'EOF3'
fn main -> i32:
    let x = comptime if true then 1
    x
EOF3
expect_run_fail "$tmpdir/comptime_if_missing_else_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase6 comptime-if/for tests: $failures failure(s)"
  exit 1
fi

echo "phase6 comptime-if/for tests: PASS"
