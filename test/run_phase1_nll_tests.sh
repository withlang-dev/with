#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase1 NLL tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "PASS(nll-pass) $file"
  else
    echo "FAIL(nll-pass) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail_msg() {
  local file="$1"
  local msg="$2"
  local out
  if out=$("$WITH_BIN" check "$file" 2>&1 >/dev/null); then
    echo "FAIL(nll-fail) $file"
    failures=$((failures + 1))
    return
  fi
  if [[ "$out" != *"$msg"* ]]; then
    echo "FAIL(nll-msg) $file"
    failures=$((failures + 1))
    return
  fi
  echo "PASS(nll-fail) $file"
}

cat >"$tmpdir/nll_shared_then_mut_ok.w" <<'EOF1'
fn main() -> i32 =
    var x: i32 = 1
    let r = &x
    let _v = *r
    let m = &mut x
    *m = 2
    x
EOF1
expect_check_pass "$tmpdir/nll_shared_then_mut_ok.w"

cat >"$tmpdir/nll_mut_then_shared_ok.w" <<'EOF2'
fn main() -> i32 =
    var x: i32 = 1
    let m = &mut x
    *m = 3
    let r = &x
    *r
EOF2
expect_check_pass "$tmpdir/nll_mut_then_shared_ok.w"

cat >"$tmpdir/nll_conflict_live_borrow_fail.w" <<'EOF3'
fn main() -> i32 =
    var x: i32 = 1
    let r = &x
    let m = &mut x
    let _v = *r
    *m = 2
    x
EOF3
expect_check_fail_msg "$tmpdir/nll_conflict_live_borrow_fail.w" "cannot borrow mutably: already borrowed"

if [[ "$failures" -ne 0 ]]; then
  echo "phase1 NLL tests: $failures failure(s)"
  exit 1
fi

echo "phase1 NLL tests: PASS"
