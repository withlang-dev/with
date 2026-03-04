#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "building bootstrap compiler for Wave 1 unit tests..."
(
  cd bootstrap
  zig build -Doptimize=Debug >/dev/null
)

WITH_BIN="./bootstrap/zig-out/bin/with"
if [[ ! -x "$WITH_BIN" ]]; then
  echo "error: missing bootstrap with binary"
  exit 1
fi

tests=(
  "test/wave1/ids_test.w"
  "test/wave1/arena_test.w"
  "test/wave1/intern_pool_test.w"
  "test/wave1/intern_pool_stress_test.w"
  "test/wave1/span_source_test.w"
  "test/wave1/source_map_test.w"
  "test/wave1/source_map_crlf_test.w"
  "test/wave1/source_map_utf8_crlf_test.w"
  "test/wave1/diagnostic_test.w"
  "test/wave1/diagnostic_multilabel_determinism_test.w"
)

failures=0
for t in "${tests[@]}"; do
  if "$WITH_BIN" run "$t" >/dev/null 2>/dev/null; then
    echo "PASS(wave1-unit) $t"
  else
    echo "FAIL(wave1-unit) $t"
    failures=$((failures + 1))
  fi
done

if [[ "$failures" -ne 0 ]]; then
  echo "wave1 unit tests: $failures failure(s)"
  exit 1
fi

echo "wave1 unit tests: PASS"
