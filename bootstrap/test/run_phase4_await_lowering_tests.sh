#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase4 await-lowering tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(await-run) $file"
  else
    echo "FAIL(await-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(await-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(await-run-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_pass "test/cases/async_basic.w"
expect_run_pass "test/cases/async_sync_bridge.w"
expect_run_pass "test/cases/async_multi.w"

cat >"$tmpdir/await_non_task_fail.w" <<'EOF1'
fn main -> i32:
    let x = 7
    let _y = x.await
EOF1
expect_run_fail "$tmpdir/await_non_task_fail.w"

cat >"$tmpdir/await_task_ok.w" <<'EOF2'
async fn plus(x: i32) -> i32:
    x + 2

fn main -> i32:
    let t = plus(40)
    let r = t.await
    if r == 42 then 0 else 1
EOF2
expect_run_pass "$tmpdir/await_task_ok.w"

cat >"$tmpdir/await_tuple_ok.w" <<'EOF3'
async fn left -> i32:
    40

async fn right -> i32:
    2

async fn third -> i32:
    7

fn main -> i32:
    let (a, b) = (left(), right()).await
    let (x, y, z) = (left(), right(), third()).await
    if a == 40 and b == 2 and x == 40 and y == 2 and z == 7 then 0 else 1
EOF3
expect_run_pass "$tmpdir/await_tuple_ok.w"

cat >"$tmpdir/await_tuple_result_try_ok.w" <<'EOF4'
async fn ok_a -> Result[i32, i32]:
    Ok(3)

async fn ok_b -> Result[i32, i32]:
    Ok(4)

async fn pair_sum -> Result[i32, i32]:
    let (a, b) = (ok_a(), ok_b()).await?
    Ok(a + b)

fn main -> i32:
    let result = pair_sum().await
    if result ?? -1 == 7 then 0 else 1
EOF4
expect_run_pass "$tmpdir/await_tuple_result_try_ok.w"

cat >"$tmpdir/await_tuple_result_try_err.w" <<'EOF4B'
async fn ok_a -> Result[i32, i32]:
    Ok(3)

async fn fail_b -> Result[i32, i32]:
    Err(99)

async fn pair_sum -> Result[i32, i32]:
    let (a, b) = (ok_a(), fail_b()).await?
    Ok(a + b)

fn main -> i32:
    let result = pair_sum().await
    if result ?? -1 == -1 then 0 else 1
EOF4B
expect_run_pass "$tmpdir/await_tuple_result_try_err.w"

cat >"$tmpdir/await_tuple_non_task_fail.w" <<'EOF5'
async fn left -> i32:
    1

fn main -> i32:
    let _ = (left(), 2).await
EOF5
expect_run_fail "$tmpdir/await_tuple_non_task_fail.w"

cat >"$tmpdir/await_tuple_arity_fail.w" <<'EOF6'
async fn left -> i32:
    1

fn main -> i32:
    let _ = ().await
    let _x = left().await
EOF6
expect_run_fail "$tmpdir/await_tuple_arity_fail.w"

cat >"$tmpdir/await_from_task_container_ok.w" <<'EOF7'
async fn work(x: i32) -> i32:
    x + 1

fn main -> i32:
    let tasks = vec![work(1), work(2), work(3)]
    let first = tasks[0].await
    let second = tasks.get(1).await
    if first == 2 and second == 3 then 0 else 1
EOF7
expect_run_pass "$tmpdir/await_from_task_container_ok.w"

cat >"$tmpdir/await_task_for_loop_ok.w" <<'EOF8'
async fn work(x: i32) -> i32:
    x

fn main -> i32:
    let tasks = vec![work(1), work(2), work(3)]
    var sum = 0
    for t in tasks:
        sum = sum + t.await
    if sum == 6 then 0 else 1
EOF8
expect_run_pass "$tmpdir/await_task_for_loop_ok.w"

cat >"$tmpdir/await_task_vec_param_async_ok.w" <<'EOF9'
async fn work(x: i32) -> i32:
    x + 1

async fn sum(tasks: Vec[Task[i32]]) -> i32:
    var total = 0
    for t in tasks:
        total = total + t.await
    total

fn main -> i32:
    let tasks = vec![work(1), work(2), work(3)]
    let out = sum(tasks).await
    if out == 9 then 0 else 1
EOF9
expect_run_pass "$tmpdir/await_task_vec_param_async_ok.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase4 await-lowering tests: $failures failure(s)"
  exit 1
fi

echo "phase4 await-lowering tests: PASS"
