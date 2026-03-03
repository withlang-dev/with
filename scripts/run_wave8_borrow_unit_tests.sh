#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SELFHOST_BIN="./with-stage2"

echo "rebuilding self-host compiler for Wave 8 borrow unit tests..."
./scripts/rebuild_selfhost.sh stage2 >/dev/null

if [[ ! -x "$SELFHOST_BIN" ]]; then
  echo "error: missing self-host compiler: $SELFHOST_BIN"
  exit 1
fi

failures=0

expect_pass() {
  local file="$1"
  if "$SELFHOST_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "PASS(wave8-unit-pass) $file"
  else
    echo "FAIL(wave8-unit-pass) $file"
    failures=$((failures + 1))
  fi
}

expect_fail_msg() {
  local file="$1"
  local msg="$2"
  local out
  if out=$("$SELFHOST_BIN" check "$file" 2>&1 >/dev/null); then
    echo "FAIL(wave8-unit-fail) $file"
    failures=$((failures + 1))
    return
  fi
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

expect_pass "test/wave8/cases/borrow_shared_shared_ok.w"
expect_pass "test/wave8/cases/disjoint_fields_ok.w"
expect_pass "test/wave8/cases/cfg_branch_borrow_ok.w"
expect_pass "test/wave8/cases/nll_shared_then_mut_ok.w"
expect_pass "test/wave8/cases/nll_mut_then_shared_ok.w"
expect_pass "test/wave8/cases/move_reinit_after_move_ok.w"
expect_pass "test/wave8/cases/copy_type_copy_i32_ok.w"
expect_pass "test/wave8/cases/copy_type_copy_struct_ok.w"
expect_pass "test/wave8/cases/copy_drop_exclusive_copy_only_ok.w"
expect_pass "test/wave8/cases/drop_order_scope_check_ok.w"
expect_pass "test/wave8/cases/drop_order_early_return_check_ok.w"
expect_pass "test/wave8/cases/task_ephemeral_owned_ok.w"
expect_pass "test/wave8/cases/task_ephemeral_byref_ok.w"

expect_fail_msg "test/wave8/cases/borrow_shared_mut_fail.w" "cannot borrow mutably: already borrowed"
expect_fail_msg "test/wave8/cases/borrow_mut_mut_fail.w" "cannot borrow mutably: already mutably borrowed"
expect_fail_msg "test/wave8/cases/borrow_mut_shared_fail.w" "cannot borrow: already mutably borrowed"
expect_fail_msg "test/wave8/cases/same_field_conflict_fail.w" "cannot borrow mutably: already borrowed"
expect_fail_msg "test/wave8/cases/whole_place_conflict_fail.w" "cannot borrow: already mutably borrowed"
expect_fail_msg "test/wave8/cases/nll_conflict_live_borrow_fail.w" "cannot borrow mutably: already borrowed"
expect_fail_msg "test/wave8/cases/use_after_move_let_fail.w" "use of moved value"
expect_fail_msg "test/wave8/cases/use_after_move_assign_fail.w" "use of moved value"
expect_fail_msg "test/wave8/cases/copy_type_noncopy_drop_fail.w" "use of moved value"
expect_fail_msg "test/wave8/cases/ephemeral_struct_fail.w" "ephemeral references cannot be stored in structs"
expect_fail_msg "test/wave8/cases/ephemeral_collection_fail.w" "ephemeral references cannot be stored in collections"
expect_fail_msg "test/wave8/cases/ephemeral_return_fail.w" "ephemeral references cannot be returned from functions"
expect_fail_msg "test/wave8/cases/ephemeral_type_return_fail.w" "ephemeral types cannot be returned from functions"
expect_fail_msg "test/wave8/cases/ephemeral_closure_capture_fail.w" "closures cannot capture ephemeral references"
expect_fail_msg "test/wave8/cases/ephemeral_nested_struct_fail.w" "ephemeral references cannot be stored in structs"
expect_fail_msg "test/wave8/cases/ephemeral_nested_collection_fail.w" "ephemeral references cannot be stored in collections"
expect_fail_msg "test/wave8/cases/ephemeral_alias_capture_fail.w" "closures cannot capture ephemeral references"

# Covered only in parity harness via KNOWN_DIVERGENCE metadata:
# - copy_drop_exclusive_copy_drop_conflict_fail.w
# - copy_drop_exclusive_noncopy_field_fail.w
# - task_ephemeral_{borrow,assign,async_block}_warn.w
# - may_suspend_guard_fail.w

if [[ "$failures" -ne 0 ]]; then
  echo "wave8 borrow unit tests: $failures failure(s)"
  exit 1
fi

echo "wave8 borrow unit tests: PASS"
