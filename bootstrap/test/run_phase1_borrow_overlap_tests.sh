#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase1 borrow-overlap tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "PASS(overlap-pass) $file"
  else
    echo "FAIL(overlap-pass) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail_msg() {
  local file="$1"
  local msg="$2"
  local out
  if out=$("$WITH_BIN" check "$file" 2>&1 >/dev/null); then
    echo "FAIL(overlap-fail) $file"
    failures=$((failures + 1))
    return
  fi
  if [[ "$out" != *"$msg"* ]]; then
    echo "FAIL(overlap-msg) $file"
    failures=$((failures + 1))
    return
  fi
  echo "PASS(overlap-fail) $file"
}

cat >"$tmpdir/borrow_shared_shared_ok.w" <<'EOF1'
fn main -> i32:
    var x: i32 = 1
    let a = &x
    let b = &x
    *a + *b
EOF1
expect_check_pass "$tmpdir/borrow_shared_shared_ok.w"

cat >"$tmpdir/borrow_shared_mut_fail.w" <<'EOF2'
fn main -> i32:
    var x: i32 = 1
    let a = &x
    let b = &mut x
    *a + *b
EOF2
expect_check_fail_msg "$tmpdir/borrow_shared_mut_fail.w" "cannot borrow mutably: already borrowed"

cat >"$tmpdir/borrow_mut_mut_fail.w" <<'EOF3'
fn main -> i32:
    var x: i32 = 1
    let a = &mut x
    let b = &mut x
    *a + *b
EOF3
expect_check_fail_msg "$tmpdir/borrow_mut_mut_fail.w" "cannot borrow mutably: already mutably borrowed"

cat >"$tmpdir/borrow_mut_shared_fail.w" <<'EOF4'
fn main -> i32:
    var x: i32 = 1
    let a = &mut x
    let b = &x
    *a + *b
EOF4
expect_check_fail_msg "$tmpdir/borrow_mut_shared_fail.w" "cannot borrow: already mutably borrowed"

if [[ "$failures" -ne 0 ]]; then
  echo "phase1 borrow-overlap tests: $failures failure(s)"
  exit 1
fi

echo "phase1 borrow-overlap tests: PASS"
