#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
"$ROOT_DIR/scripts/verify_simple_coverage.sh" \
  "test/wave6/coverage_manifest.txt" \
  "test/wave6/typed_corpus.txt" \
  "run_phase2_chained_if_let_tests.sh" \
  "run_phase5_method_resolution_order_tests.sh" \
  "run_phase5_bounds_enforcement_tests.sh"
