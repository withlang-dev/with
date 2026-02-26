#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase4 async-fn lowering tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(async-lowering-run) $file"
  else
    echo "FAIL(async-lowering-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(async-lowering-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(async-lowering-run-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_pass "test/cases/async_basic.w"
expect_run_pass "test/cases/async_multi.w"
expect_run_pass "test/cases/async_sync_bridge.w"

cat >"$tmpdir/async_lowering_extended_ok.w" <<'EOF1'
async fn inc(x: i32) -> i32 =
    x + 1

async fn twice(x: i32) -> i32 =
    let a = inc(x)
    let b = inc(x + 1)
    a.await + b.await

fn main() -> i32 =
    let t = twice(10)
    let r = t.await
    assert(r == 23)
    0
EOF1
expect_run_pass "$tmpdir/async_lowering_extended_ok.w"

cat >"$tmpdir/async_lowering_call_arity_fail.w" <<'EOF2'
async fn inc(x: i32) -> i32 =
    x + 1

fn main() -> i32 =
    let _t = inc(1, 2)
    0
EOF2
expect_run_fail "$tmpdir/async_lowering_call_arity_fail.w"

cat >"$tmpdir/async_lowering_arg_type_fail.w" <<'EOF3'
async fn inc(x: i32) -> i32 =
    x + 1

fn main() -> i32 =
    let _t = inc("oops")
    0
EOF3
expect_run_fail "$tmpdir/async_lowering_arg_type_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase4 async-fn lowering tests: $failures failure(s)"
  exit 1
fi

echo "phase4 async-fn lowering tests: PASS"
