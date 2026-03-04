#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
"$ROOT_DIR/scripts/verify_simple_coverage.sh" \
  "test/wave2/coverage_manifest.txt" \
  "test/wave2/token_corpus.txt" \
  "run_phase0_harness_tests.sh" \
  "run_phase0_snapshot_tests.sh" \
  "run_phase0_golden_dumps_tests.sh"
