#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
if [[ ! -x "$WITH_BIN" ]]; then
  echo "error: missing $WITH_BIN; run: zig build -Doptimize=Debug"
  exit 1
fi

pass_tests=(
  "test/cases/pipeline_chain.w"
  "test/cases/result_and_then.w"
  "test/cases/expect_methods.w"
  "test/cases/with_builder_expr.w"
  "test/cases/with_nonlocal_return.w"
  "test/cases/async_sync_bridge.w"
  "test/cases/select_await_three.w"
  "test/cases/trait_multibounds.w"
  "test/cases/dyn_default_dispatch.w"
)

check_tests=(
  "test/gaps/phase2_5/p2_pipeline_advanced.check_fail.w"
  "test/gaps/phase2_5/p2_if_let_chained.check_fail.w"
  "test/gaps/phase2_5/p2_param_patterns.check_fail.w"
  "test/gaps/phase2_5/p2_pipeline_match.check_fail.w"
  "test/gaps/phase2_5/p2_error_from.check_fail.w"
  "test/gaps/phase2_5/p2_record_update_shorthand.check_fail.w"
  "test/gaps/phase2_5/p4_async_block.check_fail.w"
  "test/gaps/phase2_5/p4_select_let_else.check_fail.w"
  "test/gaps/phase2_5/p4_async_scope.check_fail.w"
  "test/gaps/phase2_5/p4_no_await_guard.check_fail.w"
  "test/gaps/phase2_5/p5_where_clause.check_fail.w"
  "test/gaps/phase2_5/p5_generic_trait_method.check_fail.w"
)

run_tests=(
  "test/gaps/phase2_5/p2_enum_accessor_ref_mut.run_fail.w"
  "test/gaps/phase2_5/p2_unit_elision_result_unit.run_fail.w"
  "test/gaps/phase2_5/p3_raw_ptr_as_option.run_fail.w"
  "test/gaps/phase2_5/p3_std_fs_io.run_fail.w"
  "test/gaps/phase2_5/p4_task_cancel.run_fail.w"
)

failures=0

for t in "${pass_tests[@]}"; do
  if "$WITH_BIN" run "$t" >/dev/null 2>/dev/null; then
    echo "PASS $t"
  else
    echo "FAIL(pass) $t"
    failures=$((failures + 1))
  fi
done

for t in "${check_tests[@]}"; do
  if "$WITH_BIN" check "$t" >/dev/null 2>/dev/null; then
    echo "PASS(check) $t"
  else
    echo "FAIL(check) $t"
    failures=$((failures + 1))
  fi
done

for t in "${run_tests[@]}"; do
  if "$WITH_BIN" run "$t" >/dev/null 2>/dev/null; then
    echo "PASS(run) $t"
  else
    echo "FAIL(run) $t"
    failures=$((failures + 1))
  fi
done

if [[ "$failures" -ne 0 ]]; then
  echo "phase2_5 gap tests: $failures failure(s)"
  exit 1
fi

echo "phase2_5 gap tests: PASS"
