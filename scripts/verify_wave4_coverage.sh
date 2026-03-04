#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
"$ROOT_DIR/scripts/verify_simple_coverage.sh" \
  "test/wave4/coverage_manifest.txt" \
  "test/wave4/resolved_corpus.txt" \
  "run_phase0_name_resolution_tests.sh" \
  "run_phase0_import_path_regression_tests.sh" \
  "run_phase0_c_import_link_tests.sh"
