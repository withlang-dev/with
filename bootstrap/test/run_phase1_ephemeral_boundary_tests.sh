#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase1 ephemeral-boundary tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "PASS(ephemeral-pass) $file"
  else
    echo "FAIL(ephemeral-pass) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail_msg() {
  local file="$1"
  local msg="$2"
  local out
  if out=$("$WITH_BIN" check "$file" 2>&1 >/dev/null); then
    echo "FAIL(ephemeral-fail) $file"
    failures=$((failures + 1))
    return
  fi
  if [[ "$out" != *"$msg"* ]]; then
    echo "FAIL(ephemeral-msg) $file"
    failures=$((failures + 1))
    return
  fi
  echo "PASS(ephemeral-fail) $file"
}

cat >"$tmpdir/ephemeral_local_ok.w" <<'EOF1'
fn main -> i32:
    var x: i32 = 10
    let r = &x
    *r
EOF1
expect_check_pass "$tmpdir/ephemeral_local_ok.w"

cat >"$tmpdir/ephemeral_struct_fail.w" <<'EOF2'
type Bad = { r: &i32 }

fn main -> i32:
    0
EOF2
expect_check_fail_msg "$tmpdir/ephemeral_struct_fail.w" "ephemeral references cannot be stored in structs"

cat >"$tmpdir/ephemeral_collection_fail.w" <<'EOF3'
let bad: Vec[&i32] = 0

fn main -> i32:
    0
EOF3
expect_check_fail_msg "$tmpdir/ephemeral_collection_fail.w" "ephemeral references cannot be stored in collections"

cat >"$tmpdir/ephemeral_return_fail.w" <<'EOF4'
fn id_ref(x: &i32) -> &i32:
    x

fn main -> i32:
    0
EOF4
expect_check_fail_msg "$tmpdir/ephemeral_return_fail.w" "ephemeral references cannot be returned from functions"

cat >"$tmpdir/ephemeral_closure_capture_fail.w" <<'EOF5'
fn main -> i32:
    var x: i32 = 1
    let r = &x
    let f = || *r
    f()
EOF5
expect_check_fail_msg "$tmpdir/ephemeral_closure_capture_fail.w" "closures cannot capture ephemeral references"

if [[ "$failures" -ne 0 ]]; then
  echo "phase1 ephemeral-boundary tests: $failures failure(s)"
  exit 1
fi

echo "phase1 ephemeral-boundary tests: PASS"
