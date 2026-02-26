#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "running phase5 milestone 25.10/25.11 suites..."

failures=0

run_suite() {
  local suite="$1"
  if bash "$suite"; then
    echo "PASS(milestone-25.10-25.11) $suite"
  else
    echo "FAIL(milestone-25.10-25.11) $suite"
    failures=$((failures + 1))
  fi
}

# 25.10 Traits and coherence coverage.
run_suite "test/run_phase5_trait_definition_parsing_tests.sh"
run_suite "test/run_phase5_impl_block_parsing_tests.sh"
run_suite "test/run_phase5_orphan_coherence_tests.sh"
run_suite "test/run_phase5_method_resolution_order_tests.sh"
run_suite "test/run_phase5_trait_bounds_signatures_tests.sh"
run_suite "test/run_phase5_multiple_bounds_where_clause_tests.sh"
run_suite "test/run_phase5_bounds_enforcement_tests.sh"
run_suite "test/run_phase5_syntax_trait_wiring_tests.sh"
run_suite "test/run_phase5_dyn_trait_vtable_tests.sh"
run_suite "test/run_phase5_object_safety_diagnostics_tests.sh"
run_suite "test/run_phase5_box_ref_dyn_tests.sh"
run_suite "test/run_phase5_devirtualization_tests.sh"
run_suite "test/run_phase5_stdlib_trait_impl_coverage_tests.sh"

# 25.11 FFI and c_import coverage.
run_suite "test/run_phase0_c_import_tests.sh"
run_suite "test/run_phase0_c_import_link_tests.sh"
run_suite "test/run_phase0_c_import_milestone_tests.sh"

if [[ "$failures" -ne 0 ]]; then
  echo "phase5 milestone 25.10/25.11 tests: $failures failure(s)"
  exit 1
fi

echo "phase5 milestone 25.10/25.11 tests: PASS"
