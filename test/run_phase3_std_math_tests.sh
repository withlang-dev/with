#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase3 std.math tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(math-check) $file"
  else
    echo "FAIL(math-check) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(math-run) $file"
  else
    echo "FAIL(math-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(math-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(math-run-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_pass "lib/std/math.w"
expect_run_pass "test/cases/import_std_math.w"
expect_run_pass "test/cases/stdlib_math.w"
expect_run_pass "test/cases/float_math.w"

cat >"$tmpdir/std_math_extended_ok.w" <<'EOF1'
use std.math

fn main() -> i32 =
    assert(abs64(0 - 9) == 9)
    assert(min64(4, 9) == 4)
    assert(max64(4, 9) == 9)

    let r = round_f64(3.6)
    assert(r > 3.99)
    assert(r < 4.01)

    let t = tan_f64(0.0)
    assert(t > -0.01)
    assert(t < 0.01)

    let ln = log_f64(E)
    assert(ln > 0.99)
    assert(ln < 1.01)

    let lg = log10_f64(100.0)
    assert(lg > 1.99)
    assert(lg < 2.01)

    let ex = exp_f64(1.0)
    assert(ex > 2.71)
    assert(ex < 2.73)

    let fa = fabs_f64(0.0 - 2.5)
    assert(fa > 2.49)
    assert(fa < 2.51)

    let fm = fmod_f64(7.0, 3.0)
    assert(fm > 0.99)
    assert(fm < 1.01)

    let asn = asin_f64(0.0)
    assert(asn > -0.01)
    assert(asn < 0.01)

    let ac = acos_f64(1.0)
    assert(ac > -0.01)
    assert(ac < 0.01)

    let at = atan_f64(0.0)
    assert(at > -0.01)
    assert(at < 0.01)

    let at2 = atan2_f64(0.0, 1.0)
    assert(at2 > -0.01)
    assert(at2 < 0.01)

    0
EOF1
expect_run_pass "$tmpdir/std_math_extended_ok.w"

cat >"$tmpdir/std_math_sqrt_arity_fail.w" <<'EOF2'
use std.math

fn main() -> i32 =
    let _x = sqrt_f64()
    0
EOF2
expect_run_fail "$tmpdir/std_math_sqrt_arity_fail.w"

cat >"$tmpdir/std_math_pow_arity_fail.w" <<'EOF3'
use std.math

fn main() -> i32 =
    let _x = pow_f64(2.0)
    0
EOF3
expect_run_fail "$tmpdir/std_math_pow_arity_fail.w"

cat >"$tmpdir/std_math_abs64_type_fail.w" <<'EOF4'
use std.math

fn main() -> i32 =
    let _x = abs64("bad")
    0
EOF4
expect_run_fail "$tmpdir/std_math_abs64_type_fail.w"

cat >"$tmpdir/std_math_atan2_arity_fail.w" <<'EOF5'
use std.math

fn main() -> i32 =
    let _x = atan2_f64(1.0)
    0
EOF5
expect_run_fail "$tmpdir/std_math_atan2_arity_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase3 std.math tests: $failures failure(s)"
  exit 1
fi

echo "phase3 std.math tests: PASS"
