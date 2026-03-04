#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
"$ROOT_DIR/scripts/verify_simple_coverage.sh" \
  "test/wave8/coverage_manifest.txt" \
  "test/wave8/borrow_corpus.txt" \
  "run_phase1_nll_tests.sh" \
  "run_phase1_copy_drop_exclusive_tests.sh" \
  "run_phase1_ephemeral_boundary_tests.sh" \
  "run_phase1_drop_order_tests.sh"
