#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 default-early-exit tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(default-early-exit-run) $file"
  else
    echo "FAIL(default-early-exit-run) $file"
    failures=$((failures + 1))
  fi
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(default-early-exit-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(default-early-exit-run-fail) $file"
  fi
}

cat >"$tmpdir/default_early_return_ok.w" <<'EOF1'
fn get(flag: bool) -> ?i32:
    if flag then Some(5) else None

fn value(flag: bool) -> i32:
    let x = get(flag) ?? return 9
    x

fn main -> i32:
    if value(true) == 5 and value(false) == 9 then 0 else 1
EOF1
expect_run_pass "$tmpdir/default_early_return_ok.w"

cat >"$tmpdir/default_early_continue_break_ok.w" <<'EOF2'
fn pick(i: i32) -> ?i32:
    if i % 2 == 0 then Some(i) else None

fn main -> i32:
    var sum = 0
    for i in 0..6:
        let v = pick(i) ?? continue
        if i == 4: break
        sum = sum + v
    if sum == 2 then 0 else 1
EOF2
expect_run_pass "$tmpdir/default_early_continue_break_ok.w"

cat >"$tmpdir/default_early_result_return_ok.w" <<'EOF3'
fn parse(flag: bool) -> Result[i32, i32]:
    if flag then Ok(7) else Err(1)

fn unwrap_or_return(flag: bool) -> i32:
    let v = parse(flag) ?? return 11
    v

fn main -> i32:
    if unwrap_or_return(true) == 7 and unwrap_or_return(false) == 11 then 0 else 1
EOF3
expect_run_pass "$tmpdir/default_early_result_return_ok.w"

cat >"$tmpdir/default_early_continue_outside_loop_fail.w" <<'EOF4'
fn main -> i32:
    let _x = None ?? continue
EOF4
expect_run_fail "$tmpdir/default_early_continue_outside_loop_fail.w"

cat >"$tmpdir/default_early_break_outside_loop_fail.w" <<'EOF5'
fn main -> i32:
    let _x = None ?? break
EOF5
expect_run_fail "$tmpdir/default_early_break_outside_loop_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 default-early-exit tests: $failures failure(s)"
  exit 1
fi

echo "phase2 default-early-exit tests: PASS"
