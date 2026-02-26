#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 with-nonlocal-control tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(with-control-run) $file"
  else
    echo "FAIL(with-control-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(with-control-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(with-control-fail) $file"
  fi
}

cat >"$tmpdir/with_nonlocal_return_ok.w" <<'EOF1'
fn f(x: i32) -> i32 =
    with x as y:
        if y == 5 then return 42
        y
    0

fn main() -> i32 =
    if f(5) == 42 and f(1) == 0 then 0 else 1
EOF1
expect_run_pass "$tmpdir/with_nonlocal_return_ok.w"

cat >"$tmpdir/with_nonlocal_loop_control_ok.w" <<'EOF2'
fn main() -> i32 =
    var i: i32 = 0
    var sum: i32 = 0
    while i < 5:
        i = i + 1
        with i as y:
            if y == 2 then continue
            if y == 4 then break
            sum = sum + y
    if sum == 4 then 0 else 1
EOF2
expect_run_pass "$tmpdir/with_nonlocal_loop_control_ok.w"

cat >"$tmpdir/with_nonlocal_mut_return_ok.w" <<'EOF3'
fn f() -> i32 =
    with 1 as mut x:
        if x == 1 then return 9
        x = 2
        x
    0

fn main() -> i32 =
    if f() == 9 then 0 else 1
EOF3
expect_run_pass "$tmpdir/with_nonlocal_mut_return_ok.w"

cat >"$tmpdir/with_nonlocal_break_outside_loop_fail.w" <<'EOF4'
fn main() -> i32 =
    with 1 as x:
        break
    x
EOF4
expect_check_fail "$tmpdir/with_nonlocal_break_outside_loop_fail.w"

cat >"$tmpdir/with_nonlocal_continue_outside_loop_fail.w" <<'EOF5'
fn main() -> i32 =
    with 1 as x:
        continue
    x
EOF5
expect_check_fail "$tmpdir/with_nonlocal_continue_outside_loop_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 with-nonlocal-control tests: $failures failure(s)"
  exit 1
fi

echo "phase2 with-nonlocal-control tests: PASS"
