#!/usr/bin/env bash
# Test MIR gate removal progress.
# Runs all tests and reports pass/fail count (always exits 0).
# Usage: ./scripts/test_mir_gate.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Run the normal test suite, capture output, suppress exit code
output="$(./scripts/run_tests.sh 2>&1 || true)"
echo "$output" | tail -10
