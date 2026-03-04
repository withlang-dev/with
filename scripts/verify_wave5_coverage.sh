#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
"$ROOT_DIR/scripts/verify_simple_coverage.sh" \
  "test/wave5/coverage_manifest.txt" \
  "test/wave5/typed_corpus.txt" \
  "run_phase5_trait_definition_parsing_tests.sh" \
  "run_phase5_method_resolution_order_tests.sh" \
  "run_phase5_orphan_coherence_tests.sh"
