#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
if [[ ! -x "$WITH_BIN" ]]; then
  echo "error: missing $WITH_BIN; run: zig build -Doptimize=Debug"
  exit 1
fi

run_tests=(
  "bootstrap/test/cases/derive_all.w"
  "bootstrap/test/cases/comptime_cascade_type_api.w"
  "bootstrap/test/cases/derive_builder_generated.w"
)

check_fail_tests=(
  "bootstrap/test/gaps/phase6/p6_derive_copy_ineligible.check_fail.w"
)

failures=0

for t in "${run_tests[@]}"; do
  if "$WITH_BIN" run "$t" >/dev/null 2>/dev/null; then
    echo "PASS(run) $t"
  else
    echo "FAIL(run) $t"
    failures=$((failures + 1))
  fi
done

for t in "${check_fail_tests[@]}"; do
  if "$WITH_BIN" check "$t" >/dev/null 2>/dev/null; then
    echo "FAIL(check-fail) $t"
    failures=$((failures + 1))
  else
    echo "PASS(check-fail) $t"
  fi
done

if [[ "$failures" -ne 0 ]]; then
  echo "phase6 tests: $failures failure(s)"
  exit 1
fi

echo "phase6 tests: PASS"
