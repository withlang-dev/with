#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
source "${ROOT_DIR}/scripts/selfhost_runner.sh"

SELFHOST_BIN="./out/bin/with-stage2"
CHECK_TIMEOUT_SECS="${PARITY_CHECK_TIMEOUT_SECS:-60}"

echo "rebuilding self-host compiler for Wave 8 borrow unit tests..."
make stage2 >/dev/null

if [[ ! -x "$SELFHOST_BIN" ]]; then
  echo "error: missing self-host compiler: $SELFHOST_BIN"
  exit 1
fi

SELFHOST_BIN="$(prepare_selfhost_runner "$ROOT_DIR" "$SELFHOST_BIN")"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"; cleanup_selfhost_runner' EXIT

failures=0

expect_pass() {
  local file="$1"
  if runner_exec_capture "$CHECK_TIMEOUT_SECS" /dev/null /dev/null "$SELFHOST_BIN" check "$file"; then
    echo "PASS(wave8-unit-pass) $file"
  else
    echo "FAIL(wave8-unit-pass) $file"
    failures=$((failures + 1))
  fi
}

expect_fail_msg() {
  local file="$1"
  local msg="$2"
  local out=""
  local err="$tmpdir/${file//\//__}.fail.err"
  local rc=0
  runner_exec_capture "$CHECK_TIMEOUT_SECS" /dev/null "$err" "$SELFHOST_BIN" check "$file" || rc=$?
  if [[ "$rc" -eq 0 ]]; then
    echo "FAIL(wave8-unit-fail) $file"
    failures=$((failures + 1))
    return
  fi
  out="$(cat "$err" 2>/dev/null || true)"
  if [[ "$out" != *"$msg"* ]]; then
    echo "FAIL(wave8-unit-msg) $file"
    echo "expected message: $msg"
    echo "actual output:"
    echo "$out"
    failures=$((failures + 1))
    return
  fi
  echo "PASS(wave8-unit-fail) $file"
}

expect_warn_msg() {
  local file="$1"
  local msg="$2"
  local out=""
  local err="$tmpdir/${file//\//__}.warn.err"
  if ! runner_exec_capture "$CHECK_TIMEOUT_SECS" /dev/null "$err" "$SELFHOST_BIN" check "$file"; then
    echo "FAIL(wave8-unit-warn-status) $file"
    failures=$((failures + 1))
    return
  fi
  out="$(cat "$err" 2>/dev/null || true)"
  if [[ "$out" != *"$msg"* ]]; then
    echo "FAIL(wave8-unit-warn-msg) $file"
    echo "expected warning: $msg"
    echo "actual output:"
    echo "$out"
    failures=$((failures + 1))
    return
  fi
  echo "PASS(wave8-unit-warn) $file"
}

expect_pass "test/wave8/cases/borrow_shared_shared_ok.w"
expect_pass "test/wave8/cases/disjoint_fields_ok.w"
expect_pass "test/wave8/cases/cfg_branch_borrow_ok.w"
expect_pass "test/wave8/cases/dataflow_pred_succ_ok.w"
expect_pass "test/wave8/cases/nll_shared_then_mut_ok.w"
expect_pass "test/wave8/cases/nll_mut_then_shared_ok.w"
expect_pass "test/wave8/cases/branch_loop_disjoint_reborrow_ok.w"
expect_pass "test/wave8/cases/move_reinit_after_move_ok.w"
expect_pass "test/wave8/cases/copy_type_copy_i32_ok.w"
expect_pass "test/wave8/cases/copy_type_copy_struct_ok.w"
expect_pass "test/wave8/cases/copy_drop_exclusive_copy_only_ok.w"
expect_pass "test/wave8/cases/drop_order_scope_check_ok.w"
expect_pass "test/wave8/cases/drop_order_early_return_check_ok.w"
expect_pass "test/wave8/cases/task_ephemeral_owned_ok.w"
expect_pass "test/wave8/cases/task_ephemeral_byref_ok.w"
expect_warn_msg "test/wave8/cases/task_ephemeral_borrow_warn.w" "ephemeral Task passed by value may escape"
expect_warn_msg "test/wave8/cases/task_ephemeral_assign_warn.w" "ephemeral Task passed by value may escape"
expect_warn_msg "test/wave8/cases/task_ephemeral_async_block_warn.w" "ephemeral Task passed by value may escape"

expect_fail_msg "test/wave8/cases/borrow_shared_mut_fail.w" "cannot borrow mutably: already borrowed"
expect_fail_msg "test/wave8/cases/borrow_mut_mut_fail.w" "cannot borrow mutably: already mutably borrowed"
expect_fail_msg "test/wave8/cases/borrow_mut_shared_fail.w" "cannot borrow: already mutably borrowed"
expect_fail_msg "test/wave8/cases/same_field_conflict_fail.w" "cannot borrow mutably: already borrowed"
expect_fail_msg "test/wave8/cases/whole_place_conflict_fail.w" "cannot borrow: already mutably borrowed"
expect_fail_msg "test/wave8/cases/nll_conflict_live_borrow_fail.w" "cannot borrow mutably: already borrowed"
expect_fail_msg "test/wave8/cases/dataflow_live_conflict_fail.w" "cannot borrow mutably: already borrowed"
expect_fail_msg "test/wave8/cases/loop_same_field_reborrow_fail.w" "cannot borrow mutably: already borrowed"
expect_fail_msg "test/wave8/cases/use_after_move_let_fail.w" "use of moved value"
expect_fail_msg "test/wave8/cases/use_after_move_assign_fail.w" "use of moved value"
expect_fail_msg "test/wave8/cases/copy_type_noncopy_drop_fail.w" "use of moved value"
expect_fail_msg "test/wave8/cases/copy_drop_exclusive_copy_drop_conflict_fail.w" "type cannot be both Copy and Drop"
expect_fail_msg "test/wave8/cases/copy_drop_exclusive_noncopy_field_fail.w" "cannot derive Copy for a type with non-Copy fields"
expect_fail_msg "test/wave8/cases/ephemeral_struct_fail.w" "ephemeral references cannot be stored in structs"
expect_fail_msg "test/wave8/cases/ephemeral_collection_fail.w" "ephemeral references cannot be stored in collections"
expect_fail_msg "test/wave8/cases/ephemeral_return_fail.w" "ephemeral references cannot be returned from functions"
expect_fail_msg "test/wave8/cases/ephemeral_type_return_fail.w" "ephemeral types cannot be returned from functions"
expect_fail_msg "test/wave8/cases/ephemeral_closure_capture_fail.w" "closures cannot capture ephemeral references"
expect_fail_msg "test/wave8/cases/ephemeral_nested_struct_fail.w" "ephemeral references cannot be stored in structs"
expect_fail_msg "test/wave8/cases/ephemeral_nested_collection_fail.w" "ephemeral references cannot be stored in collections"
expect_fail_msg "test/wave8/cases/ephemeral_alias_capture_fail.w" "closures cannot capture ephemeral references"
expect_fail_msg "test/wave8/cases/may_suspend_guard_fail.w" "E0701: may_suspend call while no_await_guard value is live"

if [[ "$failures" -ne 0 ]]; then
  echo "wave8 borrow unit tests: $failures failure(s)"
  exit 1
fi

echo "wave8 borrow unit tests: PASS"
