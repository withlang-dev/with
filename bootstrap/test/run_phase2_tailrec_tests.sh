#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 tailrec tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(tailrec-run) $file"
  else
    echo "FAIL(tailrec-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_fail_msg() {
  local file="$1"
  local msg="$2"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(tailrec-check-fail) $file"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$tmpdir/stderr.$$"; then
      echo "PASS(tailrec-check-fail) $file"
    else
      echo "FAIL(tailrec-check-msg) $file"
      cat "$tmpdir/stderr.$$"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_ir_has() {
  local file="$1"
  local needle="$2"
  local ir
  if ! ir=$("$WITH_BIN" ir "$file" 2>/dev/null); then
    echo "FAIL(tailrec-ir) $file"
    failures=$((failures + 1))
    return
  fi
  if [[ "$ir" != *"$needle"* ]]; then
    echo "FAIL(tailrec-ir-missing) $file"
    failures=$((failures + 1))
    return
  fi
  echo "PASS(tailrec-ir) $file"
}

expect_ir_lacks() {
  local file="$1"
  local needle="$2"
  local ir
  if ! ir=$("$WITH_BIN" ir "$file" 2>/dev/null); then
    echo "FAIL(tailrec-ir) $file"
    failures=$((failures + 1))
    return
  fi
  if [[ "$ir" == *"$needle"* ]]; then
    echo "FAIL(tailrec-ir-unexpected) $file"
    failures=$((failures + 1))
    return
  fi
  echo "PASS(tailrec-ir) $file"
}

cat >"$tmpdir/tailrec_valid_ok.w" <<'EOF1'
@[tailrec]
fn factorial(n: i32, acc: i32) -> i32:
    if n <= 1: acc
    else factorial(n - 1, acc * n)

fn main -> i32:
    assert(factorial(10, 1) == 3628800)
EOF1
expect_run_pass "$tmpdir/tailrec_valid_ok.w"

cat >"$tmpdir/tailrec_non_tail_fail.w" <<'EOF2'
@[tailrec]
fn bad(n: i32) -> i32:
    if n == 0: 1
    else n * bad(n - 1)

fn main -> i32: bad(5)
EOF2
expect_check_fail_msg "$tmpdir/tailrec_non_tail_fail.w" "@[tailrec] recursive call is not in tail position"

cat >"$tmpdir/tailrec_no_recursion_fail.w" <<'EOF3'
@[tailrec]
fn not_recursive(n: i32) -> i32:
    n + 1

fn main -> i32: not_recursive(1)
EOF3
expect_check_fail_msg "$tmpdir/tailrec_no_recursion_fail.w" "@[tailrec] function has no recursive tail call"

cat >"$tmpdir/tailrec_plain_recursive_ok.w" <<'EOF4'
fn fact(n: i32) -> i32:
    if n <= 1: 1
    else n * fact(n - 1)

fn main -> i32:
    assert(fact(6) == 720)
EOF4
expect_run_pass "$tmpdir/tailrec_plain_recursive_ok.w"

cat >"$tmpdir/tailrec_ir_ok.w" <<'EOF5'
@[tailrec]
fn factorial(n: i32, acc: i32) -> i32:
    if n <= 1: acc
    else factorial(n - 1, acc * n)

fn main -> i32: 0
EOF5
expect_ir_has "$tmpdir/tailrec_ir_ok.w" "tailrec.body"
expect_ir_lacks "$tmpdir/tailrec_ir_ok.w" "call i32 @factorial"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 tailrec tests: $failures failure(s)"
  exit 1
fi

echo "phase2 tailrec tests: PASS"
