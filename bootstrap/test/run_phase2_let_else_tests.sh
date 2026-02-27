#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 let-else tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(let-else-run) $file"
  else
    echo "FAIL(let-else-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(let-else-check-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(let-else-check-fail) $file"
  fi
}

cat >"$tmpdir/let_else_return_ok.w" <<'EOF1'
fn unwrap_or(opt: ?i32, fallback: i32) -> i32:
    let Some(v) = opt else return fallback
    v

fn main -> i32:
    let a = unwrap_or(Some(7), 0)
    let b = unwrap_or(None, 11)
    if a == 7 and b == 11 then 0 else 1
EOF1
expect_run_pass "$tmpdir/let_else_return_ok.w"

cat >"$tmpdir/let_else_if_diverge_ok.w" <<'EOF2'
fn pick(opt: ?i32, flag: bool) -> i32:
    let Some(v) = opt else
        if flag then return 10 else return 20
    v

fn main -> i32:
    let a = pick(Some(3), true)
    let b = pick(None, true)
    let c = pick(None, false)
    if a == 3 and b == 10 and c == 20 then 0 else 1
EOF2
expect_run_pass "$tmpdir/let_else_if_diverge_ok.w"

cat >"$tmpdir/let_else_continue_ok.w" <<'EOF3'
fn main -> i32:
    let xs = [Some(1), None, Some(3)]
    var sum = 0
    for opt in xs:
        let Some(v) = opt else continue
        sum += v
    if sum == 4 then 0 else 1
EOF3
expect_run_pass "$tmpdir/let_else_continue_ok.w"

cat >"$tmpdir/let_else_literal_fail.w" <<'EOF4'
fn main -> i32:
    let Some(v) = Some(1) else 0
    v
EOF4
expect_check_fail "$tmpdir/let_else_literal_fail.w"

cat >"$tmpdir/let_else_block_nondiverge_fail.w" <<'EOF5'
fn main -> i32:
    let Some(v) = None else
        let x = 1
        x
    v
EOF5
expect_check_fail "$tmpdir/let_else_block_nondiverge_fail.w"

cat >"$tmpdir/let_else_partial_if_fail.w" <<'EOF6'
fn main -> i32:
    let Some(v) = None else
        if true then return 0 else 1
    v
EOF6
expect_check_fail "$tmpdir/let_else_partial_if_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 let-else tests: $failures failure(s)"
  exit 1
fi

echo "phase2 let-else tests: PASS"
