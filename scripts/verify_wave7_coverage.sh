#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
"$ROOT_DIR/scripts/verify_simple_coverage.sh" \
  "test/wave7/coverage_manifest.txt" \
  "test/wave7/mir_corpus.txt" \
  "run_phase6_mir_optimizations_tests.sh" \
  "run_phase1_drop_order_tests.sh" \
  "run_phase2_let_else_tests.sh"
