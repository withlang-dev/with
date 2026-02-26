#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase4 channel tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(channel-run) $file"
  else
    echo "FAIL(channel-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_fail_msg() {
  local file="$1"
  local msg="$2"
  local stderr_file="$tmpdir/stderr.err.$$"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$stderr_file"; then
    echo "FAIL(channel-check-fail) $file"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(channel-check-fail) $file"
    else
      echo "FAIL(channel-check-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$stderr_file"
}

expect_run_pass "test/cases/channels.w"

cat >"$tmpdir/channel_bounded_capacity_one.w" <<'EOF1'
async fn producer(ch: i64) -> i32:
    send(ch, 1)
    send(ch, 2)
    send(ch, 3)

async fn consumer(ch: i64) -> i32:
    let a = recv(ch)
    let b = recv(ch)
    let c = recv(ch)
    a + b + c

fn main -> i32:
    let ch = Channel(1)
    let p = producer(ch)
    let c = consumer(ch)
    let sum = c.await
    let _ = p.await
    if sum == 6 then 0 else 1
EOF1
expect_run_pass "$tmpdir/channel_bounded_capacity_one.w"

cat >"$tmpdir/channel_unbounded_growth.w" <<'EOF2'
async fn produce(ch: i64, n: i32) -> i32:
    var i: i32 = 1
    while i <= n:
        send(ch, i)
        i = i + 1

fn main -> i32:
    let n = 600
    let ch = Channel(0)
    let p = produce(ch, n)
    let _ = p.await

    var i: i32 = 0
    var sum: i32 = 0
    while i < n:
        sum = sum + recv(ch)
        i = i + 1

    if sum == 180300 then 0 else 1
EOF2
expect_run_pass "$tmpdir/channel_unbounded_growth.w"

cat >"$tmpdir/channel_close_empty_recv.w" <<'EOF3'
fn main -> i32:
    let ch = Channel(2)
    close(ch)
    let v = recv(ch)
    if v == -1 then 0 else 1
EOF3
expect_run_pass "$tmpdir/channel_close_empty_recv.w"

cat >"$tmpdir/channel_close_drains_then_sentinel.w" <<'EOF4'
fn main -> i32:
    let ch = Channel(2)
    send(ch, 7)
    close(ch)
    let a = recv(ch)
    let b = recv(ch)
    if a == 7 and b == -1 then 0 else 1
EOF4
expect_run_pass "$tmpdir/channel_close_drains_then_sentinel.w"

cat >"$tmpdir/channel_mpmc_two_by_two.w" <<'EOF5'
async fn p1(ch: i64) -> i32:
    send(ch, 1)
    send(ch, 2)

async fn p2(ch: i64) -> i32:
    send(ch, 3)
    send(ch, 4)

async fn csum2(ch: i64) -> i32:
    let a = recv(ch)
    let b = recv(ch)
    a + b

fn main -> i32:
    let ch = Channel(2)
    let a = p1(ch)
    let b = p2(ch)
    let c1 = csum2(ch)
    let c2 = csum2(ch)

    let s1 = c1.await
    let s2 = c2.await
    let _ = a.await
    let _ = b.await

    if s1 + s2 == 10 then 0 else 1
EOF5
expect_run_pass "$tmpdir/channel_mpmc_two_by_two.w"

cat >"$tmpdir/channel_capacity_type_fail.w" <<'EOF6'
fn main -> i32:
    let _ = Channel("oops")
EOF6
expect_check_fail_msg "$tmpdir/channel_capacity_type_fail.w" "Channel() capacity must be an integer"

cat >"$tmpdir/channel_send_arity_fail.w" <<'EOF7'
fn main -> i32:
    let ch = Channel(2)
    send(ch)
EOF7
expect_check_fail_msg "$tmpdir/channel_send_arity_fail.w" "send() expects exactly two arguments"

cat >"$tmpdir/channel_recv_arity_fail.w" <<'EOF8'
fn main -> i32:
    let ch = Channel(2)
    recv(ch, 1)
EOF8
expect_check_fail_msg "$tmpdir/channel_recv_arity_fail.w" "recv() expects exactly one argument"

cat >"$tmpdir/channel_close_arity_fail.w" <<'EOF9'
fn main -> i32:
    let ch = Channel(2)
    close(ch, 1)
EOF9
expect_check_fail_msg "$tmpdir/channel_close_arity_fail.w" "close() expects exactly one argument"

cat >"$tmpdir/channel_send_payload_type_fail.w" <<'EOF10'
fn main -> i32:
    let ch = Channel(2)
    send(ch, "text")
EOF10
expect_check_fail_msg "$tmpdir/channel_send_payload_type_fail.w" "send() currently supports integer payloads"

if [[ "$failures" -ne 0 ]]; then
  echo "phase4 channel tests: $failures failure(s)"
  exit 1
fi

echo "phase4 channel tests: PASS"
