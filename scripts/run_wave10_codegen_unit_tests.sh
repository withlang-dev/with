#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
source "${ROOT_DIR}/scripts/selfhost_runner.sh"

SELFHOST_BIN="./out/bin/with-stage2"
CHECK_TIMEOUT_SECS="${PARITY_CHECK_TIMEOUT_SECS:-60}"
RUN_TIMEOUT_SECS="${PARITY_RUN_TIMEOUT_SECS:-25}"

echo "rebuilding self-host compiler for Wave 10 codegen unit tests..."
./scripts/rebuild_selfhost.sh stage2 >/dev/null

if [[ ! -x "$SELFHOST_BIN" ]]; then
  echo "error: missing self-host compiler: $SELFHOST_BIN"
  exit 1
fi

SELFHOST_BIN="$(prepare_selfhost_runner "$ROOT_DIR" "$SELFHOST_BIN")"

cleanup_selfhost_artifacts() {
  local src="$1"
  if [[ "$src" != *.w ]]; then
    return
  fi
  local stem="${src%.w}"
  local bin_path="$stem"
  local obj_path="${stem}.o"
  if [[ -f "$bin_path" ]]; then
    unlink "$bin_path" || true
  fi
  if [[ -f "$obj_path" ]]; then
    unlink "$obj_path" || true
  fi
}

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

failures=0
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"; cleanup_selfhost_runner' EXIT

expect_check_pass() {
  local file="$1"
  if run_compiler check "$file" "$tmpdir/out" "$tmpdir/err"; then
    echo "PASS(wave10-unit-check-pass) $file"
  else
    echo "FAIL(wave10-unit-check-pass) $file"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
  fi
}

expect_run_pass() {
  local file="$1"
  if run_compiler run "$file" "$tmpdir/out" "$tmpdir/err"; then
    echo "PASS(wave10-unit-run-pass) $file"
  else
    echo "FAIL(wave10-unit-run-pass) $file"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
  fi
  cleanup_selfhost_artifacts "$file"
}

expect_build_pass() {
  local file="$1"
  if run_compiler build "$file" "$tmpdir/out" "$tmpdir/err"; then
    echo "PASS(wave10-unit-build-pass) $file"
  else
    echo "FAIL(wave10-unit-build-pass) $file"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
  fi
  cleanup_selfhost_artifacts "$file"
}

expect_check_fail_msg() {
  local file="$1"
  local msg="$2"
  if run_compiler check "$file" "$tmpdir/out" "$tmpdir/err"; then
    echo "FAIL(wave10-unit-check-fail) $file"
    failures=$((failures + 1))
    return
  fi
  if ! grep -Fq "$msg" "$tmpdir/err"; then
    echo "FAIL(wave10-unit-check-msg) $file"
    echo "expected message containing: $msg"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi
  echo "PASS(wave10-unit-check-fail) $file"
}

expect_build_fail_msg() {
  local file="$1"
  local msg="$2"
  if run_compiler build "$file" "$tmpdir/out" "$tmpdir/err"; then
    echo "FAIL(wave10-unit-build-fail) $file"
    failures=$((failures + 1))
    cleanup_selfhost_artifacts "$file"
    return
  fi
  if ! grep -Fq "$msg" "$tmpdir/err"; then
    echo "FAIL(wave10-unit-build-msg) $file"
    echo "expected message containing: $msg"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    cleanup_selfhost_artifacts "$file"
    return
  fi
  echo "PASS(wave10-unit-build-fail) $file"
  cleanup_selfhost_artifacts "$file"
}

expect_ir_contains() {
  local file="$1"
  local needle="$2"
  if ! run_compiler ir "$file" "$tmpdir/out" "$tmpdir/err"; then
    echo "FAIL(wave10-unit-ir-run) $file"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi
  if ! grep -Fq "$needle" "$tmpdir/out"; then
    echo "FAIL(wave10-unit-ir-missing) $file"
    echo "missing IR fragment: $needle"
    failures=$((failures + 1))
    return
  fi
  echo "PASS(wave10-unit-ir-contains) $file"
}

expect_ir_not_contains() {
  local file="$1"
  local needle="$2"
  if ! run_compiler ir "$file" "$tmpdir/out" "$tmpdir/err"; then
    echo "FAIL(wave10-unit-ir-run) $file"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi
  if grep -Fq "$needle" "$tmpdir/out"; then
    echo "FAIL(wave10-unit-ir-unexpected) $file"
    echo "unexpected IR fragment: $needle"
    failures=$((failures + 1))
    return
  fi
  echo "PASS(wave10-unit-ir-not-contains) $file"
}

expect_ir_count() {
  local file="$1"
  local needle="$2"
  local expected_count="$3"
  if ! run_compiler ir "$file" "$tmpdir/out" "$tmpdir/err"; then
    echo "FAIL(wave10-unit-ir-run) $file"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi
  local actual_count
  actual_count="$(grep -F "$needle" "$tmpdir/out" | wc -l | tr -d '[:space:]')"
  if [[ "$actual_count" != "$expected_count" ]]; then
    echo "FAIL(wave10-unit-ir-count) $file"
    echo "expected $expected_count occurrence(s) of: $needle"
    echo "actual count: $actual_count"
    failures=$((failures + 1))
    return
  fi
  echo "PASS(wave10-unit-ir-count) $file"
}

expect_ir_deterministic() {
  local file="$1"
  if ! run_compiler ir "$file" "$tmpdir/out.1" "$tmpdir/err.1"; then
    echo "FAIL(wave10-unit-ir-deterministic-run1) $file"
    cat "$tmpdir/err.1" || true
    failures=$((failures + 1))
    return
  fi
  if ! run_compiler ir "$file" "$tmpdir/out.2" "$tmpdir/err.2"; then
    echo "FAIL(wave10-unit-ir-deterministic-run2) $file"
    cat "$tmpdir/err.2" || true
    failures=$((failures + 1))
    return
  fi
  if ! diff -u "$tmpdir/out.1" "$tmpdir/out.2" >/dev/null; then
    echo "FAIL(wave10-unit-ir-deterministic-diff) $file"
    failures=$((failures + 1))
    return
  fi
  echo "PASS(wave10-unit-ir-deterministic) $file"
}

expect_check_pass "test/wave10/cases/llvm_minimal.w"
expect_check_pass "test/wave10/cases/llvm_extern.w"
expect_check_pass "test/wave10/cases/abi_ref_param_autoref.w"
expect_check_pass "test/wave10/cases/abi_aggregate_roundtrip_ok.w"
expect_check_pass "test/wave10/cases/generic_type_struct_ok.w"
expect_check_pass "test/wave10/cases/box_dyn_dispatch_ok.w"
expect_check_pass "test/wave10/cases/vtable_slot_ordering_ok.w"
expect_check_pass "test/wave10/cases/devirt_known_local.w"
expect_check_pass "test/wave10/cases/devirt_unknown_param.w"
expect_check_pass "test/wave10/cases/generic_cross_module_dedup.w"
expect_check_pass "test/wave10/cases/generic_cross_module_multi_type.w"
expect_check_pass "test/wave10/cases/enum_layout_tag_payload_probe_ok.w"
expect_check_pass "test/wave9/cases/runtime_linkage_sync_ok.w"
expect_check_pass "test/wave9/cases/runtime_linkage_async_ok.w"

expect_check_fail_msg "test/wave10/cases/llvm_ir_parse_fail.w" "expected expression"
expect_check_fail_msg "test/wave10/cases/enum_shorthand_wrong_expected_fail.w" "enum variant shorthand does not match expected enum type"
expect_check_fail_msg "test/wave10/cases/generic_infer_conflict_fail.w" "cannot infer a single type"
expect_check_fail_msg "test/wave10/cases/generic_infer_uninferred_fail.w" "unknown type"
expect_check_fail_msg "test/wave10/cases/generic_fn_unknown_type_fail.w" "unknown type"
expect_check_fail_msg "test/wave10/cases/generic_type_unknown_param_fail.w" "unknown type"

expect_ir_contains "test/wave10/cases/llvm_ir_cimport.w" "declare i32 @printf"
expect_ir_contains "test/wave10/cases/llvm_ir_cimport.w" "call i32 (ptr, ...) @printf"
expect_ir_contains "test/wave10/cases/vtable_slot_ordering_ok.w" "@__vtable_Num_Duo = internal constant { ptr, ptr } { ptr @__dynwrap_Num_first, ptr @__dynwrap_Num_second }"
expect_ir_contains "test/wave10/cases/vtable_slot_ordering_ok.w" "getelementptr inbounds nuw { ptr, ptr }, ptr %4, i32 0, i32 1"
expect_ir_contains "test/wave10/cases/abi_aggregate_roundtrip_ok.w" "%Pair = type { i32, i32 }"
expect_ir_contains "test/wave10/cases/abi_aggregate_roundtrip_ok.w" "define %Pair @bounce(%Pair %0)"
expect_ir_contains "test/wave10/cases/abi_aggregate_roundtrip_ok.w" "define i32 @sum_pair(%Pair %0)"
expect_ir_contains "test/wave10/cases/single_instantiation.w" "@id__i32"
expect_ir_not_contains "test/wave10/cases/single_instantiation.w" "@id__bool"
expect_ir_not_contains "test/wave10/cases/unused_generic.w" "@id__"
expect_ir_contains "test/wave10/cases/generic_instantiation_key_order.w" "@pair_first__i32__bool"
expect_ir_not_contains "test/wave10/cases/generic_instantiation_key_order.w" "@pair_first__bool__i32"
expect_ir_contains "test/wave10/cases/generic_instantiation_reuse.w" "@id__i32"
expect_ir_contains "test/wave10/cases/generic_instantiation_reuse.w" "@id__bool"
expect_ir_not_contains "test/wave10/cases/generic_instantiation_reuse.w" "@id__i64"
expect_ir_count "test/wave10/cases/generic_instantiation_reuse.w" "define i32 @id__i32(i32" "1"
expect_ir_count "test/wave10/cases/generic_instantiation_reuse.w" "define i1 @id__bool(i1" "1"
expect_ir_count "test/wave10/cases/generic_cross_module_dedup.w" "define i32 @id__i32(i32" "1"
expect_ir_count "test/wave10/cases/generic_cross_module_dedup.w" "define i32 @choose_left__i32__bool(i32" "1"
expect_ir_count "test/wave10/cases/generic_cross_module_multi_type.w" "define i32 @id__i32(i32" "1"
expect_ir_count "test/wave10/cases/generic_cross_module_multi_type.w" "define i1 @id__bool(i1" "1"
expect_ir_contains "test/wave10/cases/enum_layout_tag_payload_probe_ok.w" "%Packet = type { i32, [4 x i8] }"
expect_ir_contains "test/wave10/cases/enum_layout_tag_payload_probe_ok.w" "switch i32 %6, label %match.default"
expect_ir_deterministic "test/wave10/cases/llvm_ir_simple.w"
expect_ir_deterministic "test/wave10/cases/vtable_slot_ordering_ok.w"

expect_build_pass "test/wave10/cases/llvm_minimal.w"
expect_build_pass "test/wave10/cases/llvm_extern.w"
expect_build_pass "test/wave10/cases/abi_ref_param_autoref.w"
expect_build_pass "test/wave10/cases/abi_aggregate_roundtrip_ok.w"
expect_build_pass "test/wave10/cases/box_dyn_dispatch_ok.w"
expect_build_pass "test/wave10/cases/vtable_slot_ordering_ok.w"
expect_build_pass "test/wave10/cases/generic_instantiation_reuse.w"
expect_build_pass "test/wave10/cases/generic_cross_module_dedup.w"
expect_build_pass "test/wave10/cases/generic_cross_module_multi_type.w"
expect_build_pass "test/wave10/cases/enum_layout_tag_payload_probe_ok.w"
expect_build_pass "test/wave9/cases/runtime_linkage_sync_ok.w"
expect_build_pass "test/wave9/cases/runtime_linkage_async_ok.w"

expect_run_pass "test/wave10/cases/llvm_minimal.w"
expect_run_pass "test/wave10/cases/llvm_extern.w"
expect_run_pass "test/wave10/cases/abi_ref_param_autoref.w"
expect_run_pass "test/wave10/cases/abi_aggregate_roundtrip_ok.w"
expect_run_pass "test/wave10/cases/generic_instantiation_reuse.w"
expect_run_pass "test/wave10/cases/generic_cross_module_dedup.w"
expect_run_pass "test/wave10/cases/generic_cross_module_multi_type.w"
expect_run_pass "bootstrap/test/cases/generic_identity.w"
expect_run_pass "bootstrap/test/cases/generic_struct_fn.w"
expect_run_pass "bootstrap/test/cases/dyn_dispatch.w"
expect_run_pass "bootstrap/test/cases/dyn_default_dispatch.w"
expect_run_pass "test/wave10/cases/box_dyn_dispatch_ok.w"
expect_run_pass "test/wave10/cases/vtable_slot_ordering_ok.w"
expect_run_pass "test/wave10/cases/devirt_known_local.w"
expect_run_pass "test/wave10/cases/devirt_unknown_param.w"
expect_run_pass "test/wave10/cases/enum_layout_tag_payload_probe_ok.w"
expect_run_pass "test/wave9/cases/runtime_linkage_sync_ok.w"
expect_run_pass "test/wave9/cases/runtime_linkage_async_ok.w"

# Covered in parity harness as KNOWN_DIVERGENCE:
# - enum shorthand context acceptance
# - enum accessor runtime output mismatch
# - object-safety diagnostics
# - enum_accessor_ref IR capability difference

if [[ "$failures" -ne 0 ]]; then
  echo "wave10 codegen unit tests: $failures failure(s)"
  exit 1
fi

echo "wave10 codegen unit tests: PASS"
