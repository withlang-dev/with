#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
"$ROOT_DIR/scripts/verify_simple_coverage.sh" \
  "test/wave3/coverage_manifest.txt" \
  "test/wave3/ast_corpus.txt" \
  "run_phase2_if_let_tests.sh" \
  "run_phase2_param_patterns_tests.sh" \
  "run_phase2_chained_if_let_tests.sh"
