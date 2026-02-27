#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase5 multiple-bounds/where-clause tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(multi-bounds-where-run) $file"
  else
    echo "FAIL(multi-bounds-where-run) $file"
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
    echo "FAIL(multi-bounds-where-check-fail) $file"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(multi-bounds-where-check-fail) $file"
    else
      echo "FAIL(multi-bounds-where-check-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$stderr_file"
}

# Existing multiple-bound / where-clause coverage.
expect_run_pass "bootstrap/test/cases/trait_multibounds.w"
expect_run_pass "bootstrap/test/cases/multi_trait_bounds.w"
expect_run_pass "bootstrap/test/cases/where_clause.w"
expect_run_pass "bootstrap/test/cases/where_multi_bound.w"
expect_run_pass "bootstrap/test/cases/p5_where_clause.w"

# Bound merge across signature and where-clause.
cat >"$tmpdir/where_merges_with_signature_bounds_ok.w" <<'EOF1'
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
        self.v + 1

fn sum_ab[T: A](x: T) -> i32 where T: B:
    x.a() + x.b()

fn main -> i32:
    let x = X { v: 5 }
    if sum_ab(x) == 11 then 0 else 1
EOF1
expect_run_pass "$tmpdir/where_merges_with_signature_bounds_ok.w"

# Multiple bounds: missing one required trait must fail.
cat >"$tmpdir/multi_bound_missing_trait_fail.w" <<'EOF2'
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
expect_check_fail_msg "$tmpdir/multi_bound_missing_trait_fail.w" "does not implement trait 'B' required by bound 'T: B'"

# Malformed where-clause bound syntax must fail.
cat >"$tmpdir/where_malformed_bound_fail.w" <<'EOF3'
fn bad[T](x: T) -> i32 where T::
    0

fn main -> i32: 0
EOF3
expect_check_fail_msg "$tmpdir/where_malformed_bound_fail.w" "expected type bound name"

# where clause must reference an existing type parameter.
cat >"$tmpdir/where_unknown_type_param_fail.w" <<'EOF4'
trait A =
    fn a(self: Self) -> i32

fn bad[T](x: T) -> i32 where U: A:
    0

fn main -> i32: 0
EOF4
expect_check_fail_msg "$tmpdir/where_unknown_type_param_fail.w" "where clause references unknown type parameter"

if [[ "$failures" -ne 0 ]]; then
  echo "phase5 multiple-bounds/where-clause tests: $failures failure(s)"
  exit 1
fi

echo "phase5 multiple-bounds/where-clause tests: PASS"
