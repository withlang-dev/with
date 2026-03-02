#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "building bootstrap compiler for Wave 3 parser unit tests..."
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
  "test/wave3/parser_unit_test.w"
)

failures=0
for t in "${tests[@]}"; do
  if "$WITH_BIN" run "$t" >/dev/null 2>/dev/null; then
    echo "PASS(wave3-parser-unit) $t"
  else
    echo "FAIL(wave3-parser-unit) $t"
    failures=$((failures + 1))
  fi
done

if [[ "$failures" -ne 0 ]]; then
  echo "wave3 parser unit tests: $failures failure(s)"
  exit 1
fi

echo "wave3 parser unit tests: PASS"
