#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 closure-capture-analysis tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(closure-capture-run) $file"
  else
    echo "FAIL(closure-capture-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail_msg() {
  local file="$1"
  local msg="$2"
  local out
  if out="$("$WITH_BIN" check "$file" 2>&1 >/dev/null)"; then
    echo "FAIL(closure-capture-fail) $file"
    failures=$((failures + 1))
    return
  fi
  if grep -Fq "$msg" <<<"$out"; then
    echo "PASS(closure-capture-fail) $file"
  else
    echo "FAIL(closure-capture-msg) $file"
    failures=$((failures + 1))
  fi
}

cat >"$tmpdir/closure_capture_single_ok.w" <<'EOF1'
fn apply(f: fn(i32) -> i32, x: i32) -> i32:
    f(x)

fn main -> i32:
    let offset = 3
    let add = |x| x + offset
    if apply(add, 7) == 10 then 0 else 1
EOF1
expect_run_pass "$tmpdir/closure_capture_single_ok.w"

cat >"$tmpdir/closure_capture_multi_ok.w" <<'EOF2'
fn apply(f: fn(i32) -> i32, x: i32) -> i32:
    f(x)

fn main -> i32:
    let a = 2
    let b = 5
    let mix = |x| x * a + b
    if apply(mix, 4) == 13 then 0 else 1
EOF2
expect_run_pass "$tmpdir/closure_capture_multi_ok.w"

cat >"$tmpdir/closure_capture_ephemeral_ref_fail.w" <<'EOF3'
fn main -> i32:
    let value = 10
    let r = &value
    let f = |x| x + *r
    f(1)
EOF3
expect_check_fail_msg "$tmpdir/closure_capture_ephemeral_ref_fail.w" "closures cannot capture ephemeral references"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 closure-capture-analysis tests: $failures failure(s)"
  exit 1
fi

echo "phase2 closure-capture-analysis tests: PASS"
