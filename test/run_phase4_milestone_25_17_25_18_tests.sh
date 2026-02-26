#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase4 milestone 25.17/25.18 tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(milestone-run) $file"
  else
    echo "FAIL(milestone-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_build_warn_msg() {
  local file="$1"
  local msg="$2"
  local stderr_file="$tmpdir/stderr.warn.$$"
  if "$WITH_BIN" build "$file" >/dev/null 2>"$stderr_file"; then
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(milestone-build-warn) $file"
    else
      echo "FAIL(milestone-build-warn-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  else
    echo "FAIL(milestone-build-warn) $file"
    cat "$stderr_file"
    failures=$((failures + 1))
  fi
  rm -f "$stderr_file"
}

expect_build_no_warn_msg() {
  local file="$1"
  local msg="$2"
  local stderr_file="$tmpdir/stderr.nowarn.$$"
  if "$WITH_BIN" build "$file" >/dev/null 2>"$stderr_file"; then
    if grep -Fq "$msg" "$stderr_file"; then
      echo "FAIL(milestone-build-unexpected-warn) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    else
      echo "PASS(milestone-build-no-warn) $file"
    fi
  else
    echo "FAIL(milestone-build-no-warn) $file"
    cat "$stderr_file"
    failures=$((failures + 1))
  fi
  rm -f "$stderr_file"
}

cat >"$tmpdir/milestone_async_call_unrestricted_ok.w" <<'EOF1'
async fn inc(x: i32) -> i32: x + 1

fn call_async(x: i32) -> i32:
    let t = inc(x)
    t.await

fn main -> i32:
    if call_async(41) == 42 then 0 else 1
EOF1
expect_run_pass "$tmpdir/milestone_async_call_unrestricted_ok.w"

cat >"$tmpdir/milestone_parallel_await_ok.w" <<'EOF2'
async fn one -> i32: 1
async fn two -> i32: 2

fn main -> i32:
    let t1 = one()
    let t2 = two()
    if t1.await + t2.await == 3 then 0 else 1
EOF2
expect_run_pass "$tmpdir/milestone_parallel_await_ok.w"

cat >"$tmpdir/milestone_structured_scope_spawn_ok.w" <<'EOF3'
async fn work(v: i32) -> i32: v * 2

fn main -> i32:
    let scoped = async scope |s|:
        let a = s.track(work(10))
        let b = s.track(work(11))
        a.await + b.await
    spawn work(99)
    if scoped == 42 then 0 else 1
EOF3
expect_run_pass "$tmpdir/milestone_structured_scope_spawn_ok.w"

cat >"$tmpdir/milestone_task_value_composition_ok.w" <<'EOF4'
async fn value(x: i32) -> i32: x

fn main -> i32:
    let t = value(7)
    let keep = t
    if keep.await == 7 then 0 else 1
EOF4
expect_run_pass "$tmpdir/milestone_task_value_composition_ok.w"

cat >"$tmpdir/milestone_discarded_task_warn.w" <<'EOF5'
async fn send_analytics -> i32: 1

fn main -> i32:
    send_analytics()
    0
EOF5
expect_build_warn_msg "$tmpdir/milestone_discarded_task_warn.w" "E0801: unused Task value"

cat >"$tmpdir/milestone_spawn_detach_no_warn.w" <<'EOF6'
async fn send_analytics -> i32: 1

fn main -> i32:
    spawn send_analytics()
    0
EOF6
expect_build_no_warn_msg "$tmpdir/milestone_spawn_detach_no_warn.w" "E0801: unused Task value"

if [[ "$failures" -ne 0 ]]; then
  echo "phase4 milestone 25.17/25.18 tests: $failures failure(s)"
  exit 1
fi

echo "phase4 milestone 25.17/25.18 tests: PASS"
