#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase5 trait-bounds-signature tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(trait-bounds-signature-run) $file"
  else
    echo "FAIL(trait-bounds-signature-run) $file"
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
    echo "FAIL(trait-bounds-signature-check-fail) $file"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(trait-bounds-signature-check-fail) $file"
    else
      echo "FAIL(trait-bounds-signature-check-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$stderr_file"
}

# Existing single-bound coverage.
expect_run_pass "bootstrap/test/cases/trait_bounds.w"
expect_run_pass "bootstrap/test/cases/generic_bounds.w"

# Signature-level bound with trait-based method call in body.
cat >"$tmpdir/single_bound_signature_ok.w" <<'EOF1'
trait Addable =
    fn add(self: Self, other: Self) -> i32

type Num = { v: i32 }

impl Addable for Num =
    fn add(self: Num, other: Num) -> i32:
        self.v + other.v

fn sum_pair[T: Addable](a: T, b: T) -> i32:
    a.add(b)

fn main -> i32:
    let x = Num { v: 3 }
    let y = Num { v: 9 }
    if sum_pair(x, y) == 12 then 0 else 1
EOF1
expect_run_pass "$tmpdir/single_bound_signature_ok.w"

# Bound must be satisfiable by the concrete call-site type.
cat >"$tmpdir/single_bound_not_satisfied_fail.w" <<'EOF2'
trait Show =
    fn show(self: Self) -> i32

type A = { v: i32 }
type B = { v: i32 }

impl Show for A =
    fn show(self: A) -> i32:
        self.v

fn use_show[T: Show](x: T) -> i32:
    x.show()

fn main -> i32:
    let b = B { v: 1 }
    use_show(b)
EOF2
expect_check_fail_msg "$tmpdir/single_bound_not_satisfied_fail.w" "does not implement trait 'Show' required by bound 'T: Show'"

# Malformed bound syntax must be rejected.
cat >"$tmpdir/single_bound_malformed_syntax_fail.w" <<'EOF3'
fn bad[T:](x: T) -> i32:
    0

fn main -> i32: 0
EOF3
expect_check_fail_msg "$tmpdir/single_bound_malformed_syntax_fail.w" "expected type bound name"

if [[ "$failures" -ne 0 ]]; then
  echo "phase5 trait-bounds-signature tests: $failures failure(s)"
  exit 1
fi

echo "phase5 trait-bounds-signature tests: PASS"
