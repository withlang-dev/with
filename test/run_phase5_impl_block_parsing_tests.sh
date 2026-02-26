#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase5 impl-block parsing tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(impl-parse-run) $file"
  else
    echo "FAIL(impl-parse-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_fail() {
  local file="$1"
  local stderr_file="$tmpdir/stderr.err.$$"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$stderr_file"; then
    echo "FAIL(impl-parse-check-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(impl-parse-check-fail) $file"
  fi
  rm -f "$stderr_file"
}

expect_run_pass "test/cases/impl_block.w"
expect_run_pass "test/cases/impl_methods_complex.w"
expect_run_pass "test/cases/impl_static.w"
expect_run_pass "test/cases/trait_impl.w"

cat >"$tmpdir/impl_extend_form_ok.w" <<'EOF1'
type Counter = { value: i32 }

extend Counter =
    fn new(v: i32) -> Counter:
        Counter { value: v }
    fn get(self: Counter) -> i32:
        self.value

fn main -> i32:
    let c = Counter.new(42)
    if c.get() == 42 then 0 else 1
EOF1
expect_run_pass "$tmpdir/impl_extend_form_ok.w"

cat >"$tmpdir/impl_trait_for_form_ok.w" <<'EOF2'
trait Value =
    fn value(self: Self) -> i32

type Box = { v: i32 }

impl Value for Box =
    fn value(self: Box) -> i32:
        self.v

fn main -> i32:
    let b = Box { v: 42 }
    if b.value() == 42 then 0 else 1
EOF2
expect_run_pass "$tmpdir/impl_trait_for_form_ok.w"

cat >"$tmpdir/impl_missing_method_eq_fail.w" <<'EOF3'
type Broken = { v: i32 }

impl Broken =
    fn value(self: Broken) -> i32
        self.v

fn main -> i32: 0
EOF3
expect_check_fail "$tmpdir/impl_missing_method_eq_fail.w"

cat >"$tmpdir/impl_trait_for_missing_type_fail.w" <<'EOF4'
trait Value =
    fn value(self: Self) -> i32

impl Value for =
    fn value(self: i32) -> i32:
        self

fn main -> i32: 0
EOF4
expect_check_fail "$tmpdir/impl_trait_for_missing_type_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase5 impl-block parsing tests: $failures failure(s)"
  exit 1
fi

echo "phase5 impl-block parsing tests: PASS"
