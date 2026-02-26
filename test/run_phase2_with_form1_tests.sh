#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 with-form1 tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(with-form1-run) $file"
  else
    echo "FAIL(with-form1-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(with-form1-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(with-form1-fail) $file"
  fi
}

cat >"$tmpdir/with_enter_ok.w" <<'EOF1'
type Guard = { v: i32 }

fn Guard.enter(self: Guard) -> i32:
    self.v + 1

fn main -> i32:
    with Guard { v: 41 } as x:
        if x == 42 then 0 else 1
EOF1
expect_run_pass "$tmpdir/with_enter_ok.w"

cat >"$tmpdir/with_enter_mut_ok.w" <<'EOF2'
type Guard = { v: i32 }

fn Guard.enter_mut(self: Guard) -> i32:
    self.v

fn main -> i32:
    let out = with Guard { v: 5 } as mut x:
        x = x + 2
        x
    if out == 7 then 0 else 1
EOF2
expect_run_pass "$tmpdir/with_enter_mut_ok.w"

cat >"$tmpdir/with_form1_fallback_ok.w" <<'EOF3'
type Counter = { value: i32 }

fn make_counter(n: i32) -> Counter:
    Counter { value: n }

fn main -> i32:
    with make_counter(42) as c:
        if c.value == 42 then 0 else 1
EOF3
expect_run_pass "$tmpdir/with_form1_fallback_ok.w"

cat >"$tmpdir/with_enter_bind_type_fail.w" <<'EOF4'
type Guard = { v: i32 }

fn Guard.enter(self: Guard) -> i32:
    self.v

fn main -> i32:
    let _bad = with Guard { v: 7 } as x:
        x.v
    0
EOF4
expect_check_fail "$tmpdir/with_enter_bind_type_fail.w"

cat >"$tmpdir/with_enter_mut_bind_type_fail.w" <<'EOF5'
type Guard = { v: i32 }

fn Guard.enter_mut(self: Guard) -> i32:
    self.v

fn main -> i32:
    let _bad = with Guard { v: 7 } as mut x:
        x.v = 9
        x
    0
EOF5
expect_check_fail "$tmpdir/with_enter_mut_bind_type_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 with-form1 tests: $failures failure(s)"
  exit 1
fi

echo "phase2 with-form1 tests: PASS"
