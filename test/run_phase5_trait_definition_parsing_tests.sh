#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase5 trait-definition parsing tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(trait-def-run) $file"
  else
    echo "FAIL(trait-def-run) $file"
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
    echo "FAIL(trait-def-check-fail) $file"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(trait-def-check-fail) $file"
    else
      echo "FAIL(trait-def-check-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$stderr_file"
}

expect_check_fail() {
  local file="$1"
  local stderr_file="$tmpdir/stderr.any.$$"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$stderr_file"; then
    echo "FAIL(trait-def-check-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(trait-def-check-fail) $file"
  fi
  rm -f "$stderr_file"
}

expect_run_pass "test/cases/trait_default.w"
expect_run_pass "test/cases/trait_default_method.w"
expect_run_pass "test/cases/trait_conform.w"

cat >"$tmpdir/trait_required_and_default_parse_ok.w" <<'EOF1'
trait Compute =
    fn base(self: Self) -> i32
    fn bump(self: Self) -> i32:
        self.base() + 1

type Counter = { value: i32 }

impl Compute for Counter =
    fn base(self: Counter) -> i32:
        self.value

fn main -> i32:
    let c = Counter { value: 41 }
    if c.bump() == 42 then 0 else 1
EOF1
expect_run_pass "$tmpdir/trait_required_and_default_parse_ok.w"

cat >"$tmpdir/trait_missing_required_method_fail.w" <<'EOF2'
trait NeedsBoth =
    fn required(self: Self) -> i32
    fn optional(self: Self) -> i32:
        10

type Box = { v: i32 }

impl NeedsBoth for Box =
    fn optional(self: Box) -> i32:
        self.v

fn main -> i32: 0
EOF2
expect_check_fail_msg "$tmpdir/trait_missing_required_method_fail.w" "missing method 'required' required by trait 'NeedsBoth'"

cat >"$tmpdir/trait_malformed_default_syntax_fail.w" <<'EOF3'
trait Broken =
    fn value(self: Self) -> i32
        1

fn main -> i32: 0
EOF3
expect_check_fail "$tmpdir/trait_malformed_default_syntax_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase5 trait-definition parsing tests: $failures failure(s)"
  exit 1
fi

echo "phase5 trait-definition parsing tests: PASS"
