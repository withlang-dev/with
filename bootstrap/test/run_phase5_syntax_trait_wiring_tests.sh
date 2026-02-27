#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase5 syntax-trait wiring tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(syntax-trait-run) $file"
  else
    echo "FAIL(syntax-trait-run) $file"
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
    echo "FAIL(syntax-trait-check-fail) $file"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(syntax-trait-check-fail) $file"
    else
      echo "FAIL(syntax-trait-check-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$stderr_file"
}

# Iter protocol syntax wiring (`for` -> iter/next protocol).
expect_run_pass "bootstrap/test/cases/for_iter.w"

# Scoped/ScopedMut-style wiring (`with` -> enter/enter_mut methods).
cat >"$tmpdir/scoped_enter_methods_ok.w" <<'EOF1'
type Box = { v: i32 }

impl Box =
    fn enter(self: Box) -> i32:
        self.v

    fn enter_mut(self: Box) -> i32:
        self.v + 1

fn main -> i32:
    let b = Box { v: 4 }
    let a = with b as x:
        x
    let c = with b as mut y:
        y
    if a == 4 and c == 5 then 0 else 1
EOF1
expect_run_pass "$tmpdir/scoped_enter_methods_ok.w"

# Index wiring (`[]` -> get method protocol).
cat >"$tmpdir/index_get_protocol_ok.w" <<'EOF2'
trait IndexLike =
    fn get(self: Self, idx: i32) -> i32

type IntPair = { a: i32, b: i32 }

impl IndexLike for IntPair =
    fn get(self: IntPair, idx: i32) -> i32:
        if idx == 0 then self.a else self.b

fn main -> i32:
    let p = IntPair { a: 7, b: 9 }
    if p[0] == 7 and p[1] == 9 then 0 else 1
EOF2
expect_run_pass "$tmpdir/index_get_protocol_ok.w"

# Try wiring (Option/Result `?` behavior).
expect_run_pass "bootstrap/test/cases/option_try.w"
expect_run_pass "bootstrap/test/cases/result_try.w"

# Operator wiring (`+` -> add method protocol, via trait impl).
cat >"$tmpdir/op_add_trait_protocol_ok.w" <<'EOF3'
trait AddOps =
    fn add(self: Self, other: Self) -> Self

type Vec2 = { x: i32, y: i32 }

impl AddOps for Vec2 =
    fn add(self: Vec2, other: Vec2) -> Vec2:
        Vec2 { x: self.x + other.x, y: self.y + other.y }

fn main -> i32:
    let a = Vec2 { x: 1, y: 2 }
    let b = Vec2 { x: 3, y: 4 }
    let c = a + b
    if c.x == 4 and c.y == 6 then 0 else 1
EOF3
expect_run_pass "$tmpdir/op_add_trait_protocol_ok.w"

# Drop wiring (`Type.drop` recognized even when declared from trait impl).
cat >"$tmpdir/drop_trait_method_ok.w" <<'EOF4'
trait DropLike =
    fn drop(self: Self)

type R = { v: i32 }

impl DropLike for R =
    fn drop(self: R):
        print("")

fn main -> i32:
    let r = R { v: 1 }
EOF4
expect_run_pass "$tmpdir/drop_trait_method_ok.w"

# Display/Debug-style printing hooks.
expect_run_pass "bootstrap/test/cases/display_trait.w"

cat >"$tmpdir/debug_print_fallback_ok.w" <<'EOF5'
type D = { v: i32 }

impl D =
    fn debug(self: D) -> str:
        "D"

fn main -> i32:
    println(D { v: 1 })
EOF5
expect_run_pass "$tmpdir/debug_print_fallback_ok.w"

# Non-happy-path: `?` on non-Option/Result must fail.
cat >"$tmpdir/try_non_option_fail.w" <<'EOF6'
fn bad -> i32:
    let x = 1
    x?

fn main -> i32: 0
EOF6
expect_check_fail_msg "$tmpdir/try_non_option_fail.w" "? operator requires Option or Result"

# Non-happy-path: operator overload rhs type mismatch.
cat >"$tmpdir/op_rhs_mismatch_fail.w" <<'EOF7'
type Vec2 = { x: i32, y: i32 }

impl Vec2 =
    fn add(self: Vec2, other: Vec2) -> Vec2:
        Vec2 { x: self.x + other.x, y: self.y + other.y }

fn main -> i32:
    let v = Vec2 { x: 1, y: 2 }
    let n = 5
    let _ = v + n
EOF7
expect_check_fail_msg "$tmpdir/op_rhs_mismatch_fail.w" "operator overload rhs type mismatch"

if [[ "$failures" -ne 0 ]]; then
  echo "phase5 syntax-trait wiring tests: $failures failure(s)"
  exit 1
fi

echo "phase5 syntax-trait wiring tests: PASS"
