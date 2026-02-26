#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 default-operator tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(default-op-run) $file"
  else
    echo "FAIL(default-op-run) $file"
    failures=$((failures + 1))
  fi
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(default-op-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(default-op-run-fail) $file"
  fi
}

cat >"$tmpdir/default_option_basic_ok.w" <<'EOF1'
fn main() -> i32 =
    let some = Some(7)
    let none: ?i32 = None
    let a = some ?? 0
    let b = none ?? 42
    if a == 7 and b == 42 then 0 else 1
EOF1
expect_run_pass "$tmpdir/default_option_basic_ok.w"

cat >"$tmpdir/default_chaining_ok.w" <<'EOF2'
fn none_i32() -> ?i32 = None
fn ok_v() -> Result[i32, i32] = Ok(5)
fn err_v() -> Result[i32, i32] = Err(9)

fn main() -> i32 =
    let a = none_i32()
    let b = Some(3)
    let x = a ?? b ?? 0
    let y = err_v() ?? ok_v() ?? 0
    if x == 3 and y == 5 then 0 else 1
EOF2
expect_run_pass "$tmpdir/default_chaining_ok.w"

cat >"$tmpdir/default_laziness_ok.w" <<'EOF3'
fn boom() -> i32 =
    assert(false)
    99

fn main() -> i32 =
    let a = Some(7)
    let x = a ?? boom()
    if x == 7 then 0 else 1
EOF3
expect_run_pass "$tmpdir/default_laziness_ok.w"

cat >"$tmpdir/default_laziness_trigger_fail.w" <<'EOF4'
fn boom() -> i32 =
    assert(false)
    99

fn none_i32() -> ?i32 = None

fn main() -> i32 =
    let a = none_i32()
    let _x = a ?? boom()
    0
EOF4
expect_run_fail "$tmpdir/default_laziness_trigger_fail.w"

cat >"$tmpdir/default_non_container_fail.w" <<'EOF5'
fn main() -> i32 =
    let x = 10 ?? 42
    x
EOF5
expect_run_fail "$tmpdir/default_non_container_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 default-operator tests: $failures failure(s)"
  exit 1
fi

echo "phase2 default-operator tests: PASS"
