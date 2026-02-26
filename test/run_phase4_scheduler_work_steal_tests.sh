#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase4 scheduler work-steal tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(work-steal-run) $file"
  else
    echo "FAIL(work-steal-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(work-steal-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(work-steal-run-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_pass "test/cases/fiber_work_steal.w"
expect_run_pass "test/cases/async_multi.w"

cat >"$tmpdir/work_steal_events_arity_fail.w" <<'EOF1'
extern fn with_fiber_steal_events() -> i64

fn main -> i32:
    let _x = with_fiber_steal_events(1)
EOF1
expect_run_fail "$tmpdir/work_steal_events_arity_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase4 scheduler work-steal tests: $failures failure(s)"
  exit 1
fi

echo "phase4 scheduler work-steal tests: PASS"
