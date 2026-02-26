#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

test/run_phase1_move_assignment_tests.sh
test/run_phase1_use_after_move_tests.sh
test/run_phase1_copy_type_tests.sh
test/run_phase1_drop_order_tests.sh
test/run_phase1_copy_drop_exclusive_tests.sh
test/run_phase1_cfg_tests.sh
test/run_phase1_nll_tests.sh
test/run_phase1_borrow_overlap_tests.sh
test/run_phase1_disjoint_field_borrow_tests.sh
test/run_phase1_ephemeral_boundary_tests.sh
test/run_phase1_ephemeral_propagation_tests.sh
test/run_phase1_ref_return_provenance_tests.sh

echo "phase1 milestone tests: PASS"
