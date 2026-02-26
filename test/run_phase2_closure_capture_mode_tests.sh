#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 closure-capture-mode tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(closure-capture-mode-run) $file"
  else
    echo "FAIL(closure-capture-mode-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail_msg() {
  local file="$1"
  local msg="$2"
  local out
  if out="$("$WITH_BIN" check "$file" 2>&1 >/dev/null)"; then
    echo "FAIL(closure-capture-mode-fail) $file"
    failures=$((failures + 1))
    return
  fi
  if grep -Fq "$msg" <<<"$out"; then
    echo "PASS(closure-capture-mode-fail) $file"
  else
    echo "FAIL(closure-capture-mode-msg) $file"
    failures=$((failures + 1))
  fi
}

cat >"$tmpdir/closure_capture_copy_ok.w" <<'EOF1'
fn main() -> i32 =
    let x = 5
    let f = |n| n + x
    let y = x + 1
    if f(1) == 6 and y == 6 then 0 else 1
EOF1
expect_run_pass "$tmpdir/closure_capture_copy_ok.w"

cat >"$tmpdir/closure_capture_move_fail.w" <<'EOF2'
type Box = { v: i32 }
fn Box.drop(self: Box) -> void = assert(true)

fn main() -> i32 =
    let b = Box { v: 2 }
    let f = |n| n + b.v
    let z = b.v
    f(z)
EOF2
expect_check_fail_msg "$tmpdir/closure_capture_move_fail.w" "use of moved value"

cat >"$tmpdir/closure_capture_nonescaping_borrow_ok.w" <<'EOF3'
type Box = { v: i32 }
fn Box.drop(self: Box) -> void = assert(true)

fn apply(f: fn(i32) -> i32, x: i32) -> i32 =
    f(x)

fn main() -> i32 =
    let b = Box { v: 3 }
    let r = apply(|n| n + b.v, 1)
    let still = b.v
    if r == 4 and still == 3 then 0 else 1
EOF3
expect_run_pass "$tmpdir/closure_capture_nonescaping_borrow_ok.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 closure-capture-mode tests: $failures failure(s)"
  exit 1
fi

echo "phase2 closure-capture-mode tests: PASS"
