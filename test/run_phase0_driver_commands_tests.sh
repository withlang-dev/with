#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="$ROOT_DIR/zig-out/bin/with"
echo "building compiler binary for driver command tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d "$ROOT_DIR/.tmp_driver_commands.XXXXXX")"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_cmd_pass() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>/dev/null; then
    echo "PASS($label)"
  else
    echo "FAIL($label)"
    failures=$((failures + 1))
  fi
}

expect_cmd_fail() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>/dev/null; then
    echo "FAIL($label)"
    failures=$((failures + 1))
  else
    echo "PASS($label)"
  fi
}

cat >"$tmpdir/driver_main.w" <<'EOF1'
fn main -> i32:
    if 10 - 3 == 7 then 0 else 1
EOF1

expect_cmd_pass "driver-build" "$WITH_BIN" build "$tmpdir/driver_main.w"
if [[ -x "$tmpdir/driver_main" ]]; then
  echo "PASS(driver-build-output)"
else
  echo "FAIL(driver-build-output)"
  failures=$((failures + 1))
fi
expect_cmd_pass "driver-run" "$WITH_BIN" run "$tmpdir/driver_main.w"

mkdir -p "$tmpdir/pkg"
cat >"$tmpdir/pkg/tests.w" <<'EOF2'
use test.testing

fn add(a: i32, b: i32) -> i32:
    a + b

@[test]
fn test_add:
    assert_eq_i32(add(2, 3), 5)
EOF2
expect_cmd_pass "driver-test-package" bash -c "cd \"$tmpdir/pkg\" && \"$WITH_BIN\" test"
expect_cmd_pass "driver-test-list" bash -c "cd \"$tmpdir/pkg\" && \"$WITH_BIN\" test -list"

mkdir -p "$tmpdir/pkg_fail"
cat >"$tmpdir/pkg_fail/tests.w" <<'EOF3'
use test.testing

@[test]
fn test_fail:
    assert_eq_i32(1, 2)
EOF3
expect_cmd_fail "driver-test-failing-test" bash -c "cd \"$tmpdir/pkg_fail\" && \"$WITH_BIN\" test"

expect_cmd_fail "driver-build-missing-arg" "$WITH_BIN" build
expect_cmd_fail "driver-run-missing-arg" "$WITH_BIN" run
expect_cmd_fail "driver-test-unknown-flag" "$WITH_BIN" test "--unknown-flag"

if [[ "$failures" -ne 0 ]]; then
  echo "phase0 driver command tests: $failures failure(s)"
  exit 1
fi

echo "phase0 driver command tests: PASS"
