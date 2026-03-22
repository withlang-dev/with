#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
source "${ROOT_DIR}/scripts/selfhost_runner.sh"

SELFHOST_BIN="./out/bin/with-stage2"
CHECK_TIMEOUT_SECS="${PARITY_CHECK_TIMEOUT_SECS:-60}"
RUN_TIMEOUT_SECS="${PARITY_RUN_TIMEOUT_SECS:-25}"

echo "rebuilding self-host compiler for Wave 9 async unit tests..."
make stage2 >/dev/null

if [[ ! -x "$SELFHOST_BIN" ]]; then
  echo "error: missing self-host compiler: $SELFHOST_BIN"
  exit 1
fi

SELFHOST_BIN="$(prepare_selfhost_runner "$ROOT_DIR" "$SELFHOST_BIN")"

run_compiler() {
  local mode="$1"
  local src="$2"
  local out_file="$3"
  local err_file="$4"
  local timeout_secs="$CHECK_TIMEOUT_SECS"

  if [[ "$mode" == "run" ]]; then
    timeout_secs="$RUN_TIMEOUT_SECS"
  fi

  runner_exec_capture "$timeout_secs" "$out_file" "$err_file" "$SELFHOST_BIN" "$mode" "$src"
}

run_check_with_flag() {
  local src="$1"
  local flag="$2"
  local out_file="$3"
  local err_file="$4"
  runner_exec_capture "$CHECK_TIMEOUT_SECS" "$out_file" "$err_file" "$SELFHOST_BIN" check "$src" "$flag"
}

failures=0
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"; cleanup_selfhost_runner' EXIT

expect_check_pass() {
  local file="$1"
  if run_compiler check "$file" "$tmpdir/out" "$tmpdir/err"; then
    echo "PASS(wave9-unit-check-pass) $file"
  else
    echo "FAIL(wave9-unit-check-pass) $file"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
  fi
}

expect_run_pass() {
  local file="$1"
  if run_compiler run "$file" "$tmpdir/out" "$tmpdir/err"; then
    echo "PASS(wave9-unit-run-pass) $file"
  else
    echo "FAIL(wave9-unit-run-pass) $file"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
  fi
}

expect_check_fail_msg() {
  local file="$1"
  local msg="$2"
  if run_compiler check "$file" "$tmpdir/out" "$tmpdir/err"; then
    echo "FAIL(wave9-unit-check-fail) $file"
    failures=$((failures + 1))
    return
  fi
  if ! grep -Fq "$msg" "$tmpdir/err"; then
    echo "FAIL(wave9-unit-check-msg) $file"
    echo "expected message: $msg"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi
  echo "PASS(wave9-unit-check-fail) $file"
}

expect_build_pass_no_msg() {
  local file="$1"
  local forbidden="$2"
  if run_compiler build "$file" "$tmpdir/out" "$tmpdir/err"; then
    if grep -Fq "$forbidden" "$tmpdir/err"; then
      echo "FAIL(wave9-unit-build-unexpected-msg) $file"
      cat "$tmpdir/err" || true
      failures=$((failures + 1))
    else
      echo "PASS(wave9-unit-build-no-msg) $file"
    fi
  else
    echo "FAIL(wave9-unit-build-pass) $file"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
  fi
}

expect_check_dump_contains() {
  local file="$1"
  local flag="$2"
  local expected="$3"
  if ! run_check_with_flag "$file" "$flag" "$tmpdir/out.1" "$tmpdir/err.1"; then
    echo "FAIL(wave9-unit-check-dump-run) $file $flag"
    cat "$tmpdir/err.1" || true
    failures=$((failures + 1))
    return
  fi
  if ! run_check_with_flag "$file" "$flag" "$tmpdir/out.2" "$tmpdir/err.2"; then
    echo "FAIL(wave9-unit-check-dump-rerun) $file $flag"
    cat "$tmpdir/err.2" || true
    failures=$((failures + 1))
    return
  fi
  if ! grep -Fq "$expected" "$tmpdir/out.1"; then
    echo "FAIL(wave9-unit-check-dump-contains) $file $flag"
    failures=$((failures + 1))
    return
  fi
  if ! diff -u "$tmpdir/out.1" "$tmpdir/out.2" >/dev/null; then
    echo "FAIL(wave9-unit-check-dump-deterministic) $file $flag"
    failures=$((failures + 1))
    return
  fi
  echo "PASS(wave9-unit-check-dump) $file $flag"
}

expect_check_pass "test/wave9/cases/async_basic_ok.w"
expect_check_pass "test/wave9/cases/async_scope_track_and_await_ok.w"
expect_check_pass "test/wave9/cases/select_await_prefer_fast_ok.w"
expect_check_pass "test/wave9/cases/spawn_async_fn_ok.w"
expect_check_pass "test/wave9/cases/async_block_inline_await_ok.w"
expect_check_pass "test/wave9/cases/task_must_use_await_ok.w"
expect_check_pass "test/wave9/cases/runtime_linkage_sync_ok.w"
expect_check_pass "test/wave9/cases/runtime_linkage_async_ok.w"
expect_check_pass "test/wave9/cases/channel_send_owned_ok.w"
expect_check_pass "test/wave9/cases/channel_cancel_interaction_ok.w"
expect_check_pass "test/wave9/cases/select_await_tie_deterministic_ok.w"

expect_check_fail_msg "test/wave9/cases/await_non_task_fail.w" "await requires a Task value"
expect_check_fail_msg "test/wave9/cases/spawn_non_task_fail.w" "spawn requires a Task value"
expect_check_fail_msg "test/wave9/cases/select_non_task_fail.w" "select await arm requires a Task value"
expect_check_fail_msg "test/wave9/cases/select_empty_fail.w" "select await requires at least one arm"
expect_check_fail_msg "test/wave9/cases/track_non_task_fail.w" "track() requires a Task value"
expect_check_fail_msg "test/wave9/cases/track_outside_fail.w" "track() is only available inside async scope"
expect_check_fail_msg "test/wave9/cases/yield_outside_generator_fail.w" "yield used outside generator function"

expect_run_pass "test/wave9/cases/async_basic_ok.w"
expect_run_pass "test/wave9/cases/async_scope_track_and_await_ok.w"
expect_run_pass "test/wave9/cases/select_await_prefer_fast_ok.w"
expect_run_pass "test/wave9/cases/spawn_async_fn_ok.w"
expect_run_pass "test/wave9/cases/async_block_inline_await_ok.w"
expect_run_pass "test/wave9/cases/task_must_use_await_ok.w"
expect_run_pass "test/wave9/cases/runtime_linkage_sync_ok.w"
expect_run_pass "test/wave9/cases/runtime_linkage_async_ok.w"
expect_run_pass "test/wave9/cases/channel_send_owned_ok.w"
expect_run_pass "test/wave9/cases/channel_cancel_interaction_ok.w"
expect_run_pass "test/wave9/cases/select_await_tie_deterministic_ok.w"

expect_build_pass_no_msg "test/wave9/cases/task_must_use_await_ok.w" "E0801: unused Task value"
expect_build_pass_no_msg "test/wave9/cases/spawn_async_fn_ok.w" "E0801: unused Task value"
expect_build_pass_no_msg "test/wave9/cases/runtime_linkage_sync_ok.w" "warning:"
expect_build_pass_no_msg "test/wave9/cases/runtime_linkage_async_ok.w" "warning:"
expect_build_pass_no_msg "test/wave9/cases/channel_cancel_interaction_ok.w" "warning:"
expect_build_pass_no_msg "test/wave9/cases/select_await_tie_deterministic_ok.w" "warning:"

expect_check_dump_contains "test/wave9/cases/async_basic_ok.w" "--dump-async-mir" "async-mir module bodies="
expect_check_dump_contains "test/wave9/cases/select_await_prefer_fast_ok.w" "--dump-async-mir" "select_await"
expect_check_dump_contains "test/wave9/cases/select_await_tie_deterministic_ok.w" "--dump-async-mir" "select_await"
expect_check_dump_contains "test/wave9/cases/async_scope_track_and_await_ok.w" "--dump-async-mir" "suspend[1] await"
expect_check_dump_contains "test/wave9/cases/runtime_linkage_sync_ok.w" "--dump-async-mir" "suspend_points=0"
expect_check_dump_contains "test/wave9/cases/runtime_linkage_async_ok.w" "--dump-async-mir" "suspend_points=1"

# Covered in parity harness as KNOWN_DIVERGENCE:
# - test/wave9/cases/async_block_inline_await_ok.w (Stage0 runtime instability)
# - test/wave9/cases/select_await_prefer_fast_ok.w (Stage0 runtime instability)

if [[ "$failures" -ne 0 ]]; then
  echo "wave9 async unit tests: $failures failure(s)"
  exit 1
fi

echo "wave9 async unit tests: PASS"
