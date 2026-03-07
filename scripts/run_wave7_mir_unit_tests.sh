#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
source "${ROOT_DIR}/scripts/selfhost_runner.sh"

SELFHOST_BIN="./out/bin/with-stage2"
CHECK_TIMEOUT_SECS="${PARITY_CHECK_TIMEOUT_SECS:-60}"

echo "rebuilding self-host compiler for Wave 7 MIR unit tests..."
./scripts/rebuild_selfhost.sh stage2 >/dev/null

if [[ ! -x "$SELFHOST_BIN" ]]; then
  echo "error: missing self-host compiler: $SELFHOST_BIN"
  exit 1
fi

SELFHOST_BIN="$(prepare_selfhost_runner "$ROOT_DIR" "$SELFHOST_BIN")"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"; cleanup_selfhost_runner' EXIT

failures=0

run_expect_pattern() {
  local name="$1"
  local src="$2"
  local pattern="$3"
  local out="$tmpdir/${name}.out"
  local err="$tmpdir/${name}.err"

  if ! runner_exec_capture "$CHECK_TIMEOUT_SECS" "$out" "$err" "$SELFHOST_BIN" check "$src" --dump-mir; then
    echo "FAIL(wave7-unit-check) $name: $src"
    cat "$err"
    failures=$((failures + 1))
    return
  fi

  if ! grep -Eq "$pattern" "$out"; then
    echo "FAIL(wave7-unit-pattern) $name: $src pattern=$pattern"
    cat "$out"
    failures=$((failures + 1))
    return
  fi

  echo "PASS(wave7-unit) $name"
}

run_expect_no_pattern() {
  local name="$1"
  local src="$2"
  local pattern="$3"
  local out="$tmpdir/${name}.out"
  local err="$tmpdir/${name}.err"

  if ! runner_exec_capture "$CHECK_TIMEOUT_SECS" "$out" "$err" "$SELFHOST_BIN" check "$src" --dump-mir; then
    echo "FAIL(wave7-unit-check) $name: $src"
    cat "$err"
    failures=$((failures + 1))
    return
  fi

  if grep -Eq "$pattern" "$out"; then
    echo "FAIL(wave7-unit-no-pattern) $name: $src unexpected_pattern=$pattern"
    cat "$out"
    failures=$((failures + 1))
    return
  fi

  echo "PASS(wave7-unit) $name"
}

run_storage_pairing_check() {
  local name="$1"
  local src="$2"
  local min_live="$3"
  local out="$tmpdir/${name}.out"
  local err="$tmpdir/${name}.err"

  if ! runner_exec_capture "$CHECK_TIMEOUT_SECS" "$out" "$err" "$SELFHOST_BIN" check "$src" --dump-mir; then
    echo "FAIL(wave7-unit-storage-check-run) $name: $src"
    cat "$err"
    failures=$((failures + 1))
    return
  fi

  local live_count
  live_count="$(grep -o 'StorageLive(_[0-9][0-9]*)' "$out" | wc -l | tr -d '[:space:]')"
  if [[ "$live_count" -lt "$min_live" ]]; then
    echo "FAIL(wave7-unit-storage-live-count) $name: $src expected>=$min_live got=$live_count"
    failures=$((failures + 1))
    return
  fi

  local bad=0
  while IFS= read -r dead; do
    [[ -z "$dead" ]] && continue
    local id
    id="$(echo "$dead" | sed -E 's/StorageDead\\((_([0-9]+))\\)/\\1/')"
    if ! grep -q "StorageLive(${id})" "$out"; then
      bad=1
      break
    fi
  done < <(grep -o 'StorageDead(_[0-9][0-9]*)' "$out" || true)

  if [[ "$bad" -ne 0 ]]; then
    echo "FAIL(wave7-unit-storage-pairing) $name: $src has StorageDead without prior StorageLive"
    failures=$((failures + 1))
    return
  fi

  echo "PASS(wave7-unit-storage-pairing) $name"
}

run_determinism_check() {
  local name="$1"
  local src="$2"
  local out1="$tmpdir/${name}.det.1"
  local out2="$tmpdir/${name}.det.2"
  local err="$tmpdir/${name}.det.err"

  if ! runner_exec_capture "$CHECK_TIMEOUT_SECS" "$out1" "$err" "$SELFHOST_BIN" check "$src" --dump-mir; then
    echo "FAIL(wave7-unit-determinism-run1) $name: $src"
    cat "$err"
    failures=$((failures + 1))
    return
  fi
  if ! runner_exec_capture "$CHECK_TIMEOUT_SECS" "$out2" /dev/null "$SELFHOST_BIN" check "$src" --dump-mir; then
    echo "FAIL(wave7-unit-determinism-run2) $name: $src"
    failures=$((failures + 1))
    return
  fi
  if ! diff -u "$out1" "$out2" >/dev/null; then
    echo "FAIL(wave7-unit-determinism-diff) $name: $src"
    diff -u "$out1" "$out2" || true
    failures=$((failures + 1))
    return
  fi
  echo "PASS(wave7-unit-determinism) $name"
}

# MirBody construction primitives / CFG scaffolding.
run_expect_pattern "builder_blocks" "bootstrap/test/cases/assign.w" "^  bb0:"
run_expect_pattern "builder_terminator" "bootstrap/test/cases/assign.w" "goto -> bb|return;"
run_expect_pattern "builder_storage_live" "bootstrap/test/cases/assign.w" "StorageLive\\(_"

# Literals / arithmetic / field access.
run_expect_pattern "lower_literals" "bootstrap/test/cases/arithmetic_mixed.w" "const [0-9]+(i32|ty[0-9]+)|const true|const false"
run_expect_pattern "lower_arithmetic" "bootstrap/test/cases/arithmetic_mixed.w" "binop\\(add|binop\\(sub|binop\\(mul|binop\\(div"
run_expect_pattern "lower_field_access" "bootstrap/test/cases/record_update.w" "copy _[0-9]+\\.f"

# Blocks / let / let-else.
run_expect_pattern "lower_block_let" "bootstrap/test/cases/assign.w" "StorageLive\\(_"
run_expect_pattern "lower_let_else_switch" "bootstrap/test/cases/let_else.w" "switchInt\\("

# Control flow.
run_expect_pattern "lower_if_else" "bootstrap/test/cases/if_simple.w" "switchInt\\("
run_expect_pattern "lower_loop_backedge" "bootstrap/test/cases/loop_simple.w" "goto -> bb"
run_expect_pattern "lower_while" "bootstrap/test/cases/while_cond.w" "switchInt\\("
run_expect_pattern "lower_for" "bootstrap/test/cases/for_loop.w" "discriminant\\(|switchInt\\("
run_expect_pattern "lower_break_continue" "bootstrap/test/cases/break_continue.w" "goto -> bb"
run_expect_pattern "lower_return" "bootstrap/test/cases/early_return.w" "return;"

# Pattern matching / decision trees.
run_expect_pattern "match_literal" "bootstrap/test/cases/match_int.w" "switchInt\\("
run_expect_pattern "match_enum_discriminant" "bootstrap/test/cases/match_or_enum.w" "discriminant\\("
run_expect_pattern "match_or_pattern" "bootstrap/test/cases/match_or_enum.w" "switchInt\\("
run_expect_pattern "match_guard" "bootstrap/test/cases/match_guard.w" "switchInt\\("

# Sugar lowering.
run_expect_pattern "sugar_optional_chain" "bootstrap/test/cases/opt_chain.w" "discriminant\\(|switchInt\\("
run_expect_pattern "sugar_default_operator" "bootstrap/test/cases/option_unwrap_or.w" "switchInt\\("
run_expect_pattern "sugar_with_form1" "bootstrap/test/cases/with_form1.w" "StorageLive\\(_"
run_expect_pattern "sugar_with_form2" "bootstrap/test/cases/with_builder.w" "StorageLive\\(_"
run_expect_pattern "sugar_with_form3" "bootstrap/test/cases/with_scoped.w" "StorageLive\\(_"
run_expect_pattern "sugar_record_update" "bootstrap/test/cases/record_update.w" "aggregate\\(kind="
run_expect_pattern "sugar_pipeline" "bootstrap/test/cases/pipeline.w" "call "
run_expect_pattern "sugar_let_else" "bootstrap/test/cases/let_else.w" "switchInt\\("
run_expect_pattern "sugar_closure" "bootstrap/test/cases/closure_capture.w" "const zst\\("

# Calls and dispatch.
run_expect_pattern "call_direct" "bootstrap/test/cases/calls.w" "call "
run_expect_pattern "call_method" "bootstrap/test/cases/by_value_method.w" "call "
run_expect_pattern "call_generic_mono" "bootstrap/test/cases/generic_multi.w" "call "

# Drop insertion.
run_expect_pattern "drop_scope_exit" "test/wave7/cases/drop_scope_exit.w" "drop\\("
run_expect_pattern "drop_early_return" "test/wave7/cases/drop_early_return.w" "drop\\("
run_expect_pattern "drop_break_continue" "test/wave7/cases/drop_break_continue.w" "drop\\("
run_expect_pattern "cleanup_edge_shape_drop" "test/wave7/cases/cleanup_edge_shape.w" "drop\\("
run_expect_pattern "cleanup_edge_shape_cfg" "test/wave7/cases/cleanup_edge_shape.w" "switchInt\\("
run_expect_pattern "loop_drop_interaction_drop" "test/wave7/cases/loop_drop_interaction.w" "drop\\("
run_expect_pattern "loop_drop_interaction_backedge" "test/wave7/cases/loop_drop_interaction.w" "goto -> bb1;"
run_storage_pairing_check "storage_live_complex_pairing" "test/wave7/cases/storage_live_dead_complex.w" "6"

# Async/generator boundary before Async-MIR lowering.
run_expect_pattern "async_generator_boundary_call" "test/wave7/cases/async_generator_boundary.w" "call "
run_expect_pattern "async_generator_boundary_cfg" "test/wave7/cases/async_generator_boundary.w" "switchInt\\(|discriminant\\("
run_expect_no_pattern "async_generator_boundary_no_surface_tokens" "test/wave7/cases/async_generator_boundary.w" "await|yield|select_await|async_scope"

# Array / collection lowering.
run_expect_pattern "lower_array_aggregate" "bootstrap/test/cases/arrays.w" "aggregate\\(|const .*(i32|ty[0-9]+)"
run_expect_pattern "lower_vec_call" "bootstrap/test/cases/vec_push_pop.w" "call "
run_expect_pattern "lower_hashmap_call" "bootstrap/test/cases/hashmap_basic.w" "call "

# String lowering.
run_expect_pattern "lower_string_const" "bootstrap/test/cases/string_concat.w" "const "
run_expect_pattern "lower_string_interp" "bootstrap/test/cases/string_interp.w" "call "

# Struct / enum lowering.
run_expect_pattern "lower_struct_aggregate" "bootstrap/test/cases/structs.w" "call const \\(\\)|copy _[0-9]+\\.f"
run_expect_pattern "lower_enum_discriminant" "bootstrap/test/cases/enum_simple.w" "discriminant\\(|const "
run_expect_pattern "lower_enum_match_bind" "bootstrap/test/cases/enum_match_bind.w" "switchInt\\("
run_expect_pattern "lower_nested_field" "bootstrap/test/cases/nested_field.w" "copy _[0-9]+\\.f"

# Closure lowering.
run_expect_pattern "lower_closure_zst" "bootstrap/test/cases/closure.w" "const zst\\("
run_expect_pattern "lower_closure_capture" "bootstrap/test/cases/closure_capture_basic.w" "const zst\\("
run_expect_pattern "lower_nested_closure" "bootstrap/test/cases/nested_closure.w" "call const \\(\\)|call copy _"

# Defer lowering.
run_expect_pattern "lower_defer" "bootstrap/test/cases/defer_simple.w" "call "
run_expect_pattern "lower_defer_multi" "bootstrap/test/cases/defer_multi.w" "call "
run_expect_pattern "lower_defer_return" "bootstrap/test/cases/defer_return.w" "call const \\(\\)"

# Casting.
run_expect_pattern "lower_cast" "bootstrap/test/cases/cast.w" "cast\\(|as "

# Async lowering.
run_expect_pattern "lower_async" "bootstrap/test/cases/async_basic.w" "call "

# Trait dispatch.
run_expect_pattern "lower_dyn_dispatch" "bootstrap/test/cases/dyn_dispatch.w" "call "
run_expect_pattern "lower_trait_method" "bootstrap/test/cases/trait.w" "call "

# Float operations.
run_expect_pattern "lower_float" "bootstrap/test/cases/float_basic.w" "const.*f64|binop\\("

# Boolean operations.
run_expect_pattern "lower_bool_short_circuit" "bootstrap/test/cases/bool_short_circuit.w" "binop\\(and|binop\\(or"

# While-let lowering.
run_expect_pattern "lower_while_let" "bootstrap/test/cases/while_let.w" "switchInt\\(|discriminant\\("

# Labeled loop.
run_expect_pattern "lower_labeled_loop" "bootstrap/test/cases/labeled_loop.w" "goto -> bb"

# Break with value.
run_expect_pattern "lower_break_value" "bootstrap/test/cases/break_value.w" "goto -> bb"

# Multiple functions emitted.
run_expect_pattern "multi_fn_header" "bootstrap/test/cases/multi_fn.w" "^fn "

# No sugar tokens should remain in MIR dump text.
run_expect_no_pattern "no_sugar_tokens" "bootstrap/test/cases/with_record_methods.w" "optional_chain|record_update|with_expr|let_else|pipeline"

# Determinism checks — cover diverse features.
run_determinism_check "determinism_arithmetic" "bootstrap/test/cases/arithmetic_mixed.w"
run_determinism_check "determinism_match" "bootstrap/test/cases/match_or_enum.w"
run_determinism_check "determinism_with" "bootstrap/test/cases/with_form1.w"
run_determinism_check "determinism_enum" "bootstrap/test/cases/enum_complex.w"
run_determinism_check "determinism_closure" "bootstrap/test/cases/closure_capture.w"
run_determinism_check "determinism_struct" "bootstrap/test/cases/struct_method_chain.w"
run_determinism_check "determinism_defer" "bootstrap/test/cases/defer_complex.w"
run_determinism_check "determinism_option" "bootstrap/test/cases/option_chain.w"
run_determinism_check "determinism_result" "bootstrap/test/cases/result_chain.w"
run_determinism_check "determinism_vec" "bootstrap/test/cases/vec_operations.w"

if [[ "$failures" -ne 0 ]]; then
  echo "wave7 MIR unit tests: $failures failure(s)"
  exit 1
fi

echo "wave7 MIR unit tests: PASS"
