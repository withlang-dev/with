#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase5 bounds-enforcement tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(bounds-enforcement-run) $file"
  else
    echo "FAIL(bounds-enforcement-run) $file"
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
    echo "FAIL(bounds-enforcement-check-fail) $file"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(bounds-enforcement-check-fail) $file"
    else
      echo "FAIL(bounds-enforcement-check-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$stderr_file"
}

# Existing positive call-site/body bound coverage.
expect_run_pass "bootstrap/test/cases/trait_bounds_check.w"

# Positive: body methods are satisfied by declared bounds.
cat >"$tmpdir/bounds_body_and_callsite_ok.w" <<'EOF1'
trait A =
    fn a(self: Self) -> i32

trait B =
    fn b(self: Self) -> i32

type X = { v: i32 }

impl A for X =
    fn a(self: X) -> i32:
        self.v

impl B for X =
    fn b(self: X) -> i32:
        self.v + 10

fn sum[T: A + B](x: T) -> i32:
    x.a() + x.b()

fn main -> i32:
    let x = X { v: 2 }
    if sum(x) == 14 then 0 else 1
EOF1
expect_run_pass "$tmpdir/bounds_body_and_callsite_ok.w"

# Negative call-site: concrete type fails one required bound.
cat >"$tmpdir/bounds_callsite_missing_trait_fail.w" <<'EOF2'
trait A =
    fn a(self: Self) -> i32

trait B =
    fn b(self: Self) -> i32

type OnlyA = { v: i32 }

impl A for OnlyA =
    fn a(self: OnlyA) -> i32:
        self.v

fn use_ab[T: A + B](x: T) -> i32:
    x.a()

fn main -> i32:
    let x = OnlyA { v: 1 }
    use_ab(x)
EOF2
expect_check_fail_msg "$tmpdir/bounds_callsite_missing_trait_fail.w" "does not implement trait 'B' required by bound 'T: B'"

# Negative call-site (primitive): bounds must be enforced for primitives too.
cat >"$tmpdir/bounds_callsite_primitive_fail.w" <<'EOF3'
trait Show =
    fn show(self: Self) -> i32

fn use_show[T: Show](x: T) -> i32:
    0

fn main -> i32:
    use_show(1)
EOF3
expect_check_fail_msg "$tmpdir/bounds_callsite_primitive_fail.w" "type 'i32' does not implement trait 'Show' required by bound 'T: Show'"

# Negative body enforcement: body uses method not provided by declared bounds.
cat >"$tmpdir/bounds_body_missing_bound_fail.w" <<'EOF4'
trait A =
    fn a(self: Self) -> i32

trait B =
    fn b(self: Self) -> i32

type X = { v: i32 }

impl A for X =
    fn a(self: X) -> i32:
        self.v

fn bad[T: A](x: T) -> i32:
    x.b()

fn main -> i32:
    let x = X { v: 1 }
    bad(x)
EOF4
expect_check_fail_msg "$tmpdir/bounds_body_missing_bound_fail.w" "generic body method 'b' requires a matching trait bound"

if [[ "$failures" -ne 0 ]]; then
  echo "phase5 bounds-enforcement tests: $failures failure(s)"
  exit 1
fi

echo "phase5 bounds-enforcement tests: PASS"
