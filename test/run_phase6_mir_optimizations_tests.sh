#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "building compiler/runtime for phase6 MIR optimization tests..."
zig build -Doptimize=Debug >/dev/null

failures=0

if zig test bootstrap/MirOpt.zig >/dev/null; then
  echo "PASS(phase6-miropt-unit-tests)"
else
  echo "FAIL(phase6-miropt-unit-tests)"
  failures=$((failures + 1))
fi

# Integration coverage: existing compiler devirtualization behavior remains correct.
if bash test/run_phase5_devirtualization_tests.sh >/dev/null; then
  echo "PASS(phase6-miropt-devirt-integration)"
else
  echo "FAIL(phase6-miropt-devirt-integration)"
  failures=$((failures + 1))
fi

if [[ "$failures" -ne 0 ]]; then
  echo "phase6 MIR optimization tests: $failures failure(s)"
  exit 1
fi

echo "phase6 MIR optimization tests: PASS"
