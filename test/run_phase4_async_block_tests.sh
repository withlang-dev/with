#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase4 async-block tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(async-block-run) $file"
  else
    echo "FAIL(async-block-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(async-block-check-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(async-block-check-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_pass "test/cases/async_block.w"
expect_run_pass "test/cases/p4_async_block.w"

cat >"$tmpdir/async_block_capture_copy.w" <<'EOF1'
fn main() -> i32 =
    let mut base = 41
    let t = async:
        base + 1
    base = 100
    let r = t.await
    if r == 42 then 0 else 1
EOF1
expect_run_pass "$tmpdir/async_block_capture_copy.w"

cat >"$tmpdir/async_block_inline_await.w" <<'EOF2'
fn main() -> i32 =
    let r = (async: 5 * 9).await
    if r == 45 then 0 else 1
EOF2
expect_run_pass "$tmpdir/async_block_inline_await.w"

cat >"$tmpdir/async_block_multi_capture.w" <<'EOF3'
fn main() -> i32 =
    let a = 10
    let b = 20
    let t1 = async:
        a + b
    let t2 = async:
        a * b
    let r = t1.await + t2.await
    if r == 230 then 0 else 1
EOF3
expect_run_pass "$tmpdir/async_block_multi_capture.w"

cat >"$tmpdir/async_block_unknown_capture_fail.w" <<'EOF4'
fn main() -> i32 =
    let t = async:
        missing_value + 1
    let _ = t.await
    0
EOF4
expect_check_fail "$tmpdir/async_block_unknown_capture_fail.w"

cat >"$tmpdir/async_block_missing_body_fail.w" <<'EOF5'
fn main() -> i32 =
    let _t = async:
EOF5
expect_check_fail "$tmpdir/async_block_missing_body_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase4 async-block tests: $failures failure(s)"
  exit 1
fi

echo "phase4 async-block tests: PASS"
