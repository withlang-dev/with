#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "building bootstrap compiler for Wave 2 lexer unit tests..."
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
  "test/wave2/lexer_keywords_test.w"
  "test/wave2/lexer_operators_test.w"
  "test/wave2/lexer_literals_test.w"
  "test/wave2/lexer_structure_test.w"
)

failures=0
for t in "${tests[@]}"; do
  if "$WITH_BIN" run "$t" >/dev/null 2>/dev/null; then
    echo "PASS(wave2-lexer-unit) $t"
  else
    echo "FAIL(wave2-lexer-unit) $t"
    failures=$((failures + 1))
  fi
done

if [[ "$failures" -ne 0 ]]; then
  echo "wave2 lexer unit tests: $failures failure(s)"
  exit 1
fi

echo "wave2 lexer unit tests: PASS"
