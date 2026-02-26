#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase5 dyn-trait/vtable tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(dyn-vtable-run) $file"
  else
    echo "FAIL(dyn-vtable-run) $file"
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
    echo "FAIL(dyn-vtable-check-fail) $file"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(dyn-vtable-check-fail) $file"
    else
      echo "FAIL(dyn-vtable-check-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$stderr_file"
}

# Existing positive dynamic-dispatch/vtable coverage.
expect_run_pass "test/cases/dyn_trait.w"
expect_run_pass "test/cases/dyn_dispatch.w"
expect_run_pass "test/cases/dyn_dispatch_multi.w"
expect_run_pass "test/cases/trait_dyn_advanced.w"
expect_run_pass "test/cases/impl_trait_dyn.w"
expect_run_pass "test/cases/dyn_default_dispatch.w"

# Negative: converting a non-impl type to dyn parameter must fail in sema.
cat >"$tmpdir/dyn_missing_impl_fail.w" <<'EOF1'
trait Speak =
    fn speak(self: Self) -> i32

type Rock = { n: i32 }

fn call(x: &dyn Speak) -> i32:
    x.speak()

fn main -> i32:
    let r = Rock { n: 1 }
    call(&r)
EOF1
expect_check_fail_msg "$tmpdir/dyn_missing_impl_fail.w" "type 'Rock' does not implement trait 'Speak' required for dyn parameter"

if [[ "$failures" -ne 0 ]]; then
  echo "phase5 dyn-trait/vtable tests: $failures failure(s)"
  exit 1
fi

echo "phase5 dyn-trait/vtable tests: PASS"
