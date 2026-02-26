#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase6 comptime-cascade tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(comptime-cascade-run) $file"
  else
    echo "FAIL(comptime-cascade-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(comptime-cascade-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(comptime-cascade-run-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

# Existing cascade/type-object positive baseline.
expect_run_pass "test/cases/comptime_cascade_type_api.w"
expect_run_pass "test/cases/comptime_error.w"

# Positive: inside comptime fn, plain for/if cascade without extra comptime prefixes.
cat >"$tmpdir/comptime_cascade_if_for_ok.w" <<'EOF1'
comptime fn score(limit: i32) -> i32 =
    var out = 0
    for i in [1, 2, 3, 4]:
        if i <= limit:
            out = out + i
    out

fn main() -> i32 =
    assert(score(3) == 6)
    0
EOF1
expect_run_pass "$tmpdir/comptime_cascade_if_for_ok.w"

# Non-happy-path: taken branch inside comptime fn triggers comptime_error.
cat >"$tmpdir/comptime_cascade_taken_error_fail.w" <<'EOF2'
comptime fn bad() -> i32 =
    if true:
        comptime_error("boom")
    0

fn main() -> i32 =
    bad()
EOF2
expect_run_fail "$tmpdir/comptime_cascade_taken_error_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase6 comptime-cascade tests: $failures failure(s)"
  exit 1
fi

echo "phase6 comptime-cascade tests: PASS"
