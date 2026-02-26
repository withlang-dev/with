#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase6 repl tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_repl_contains() {
  local input="$1"
  local pattern="$2"
  local out_file="$tmpdir/repl.out.$$"
  if printf "%s" "$input" | "$WITH_BIN" repl >"$out_file" 2>&1; then
    if grep -Fq "$pattern" "$out_file"; then
      echo "PASS(phase6-repl-contains) :: $pattern"
    else
      echo "FAIL(phase6-repl-contains) :: $pattern"
      cat "$out_file"
      failures=$((failures + 1))
    fi
  else
    echo "FAIL(phase6-repl-run)"
    cat "$out_file"
    failures=$((failures + 1))
  fi
  rm -f "$out_file"
}

expect_repl_not_contains() {
  local input="$1"
  local pattern="$2"
  local out_file="$tmpdir/repl.out.$$"
  if printf "%s" "$input" | "$WITH_BIN" repl >"$out_file" 2>&1; then
    if grep -Fq "$pattern" "$out_file"; then
      echo "FAIL(phase6-repl-not-contains) :: $pattern"
      cat "$out_file"
      failures=$((failures + 1))
    else
      echo "PASS(phase6-repl-not-contains) :: $pattern"
    fi
  else
    echo "FAIL(phase6-repl-run)"
    cat "$out_file"
    failures=$((failures + 1))
  fi
  rm -f "$out_file"
}

# Positive: expression evaluation path.
expect_repl_contains $'1 + 2\n:quit\n' '3'

# Positive: persistent binding across inputs.
expect_repl_contains $'let x = 5\nx + 1\n:quit\n' '6'

# Positive: help and clear commands.
expect_repl_contains $':help\n:quit\n' 'Commands:'
expect_repl_contains $'let x = 9\n:clear\n:quit\n' '(cleared)'

# Non-happy-path: after :clear, prior binding should not keep producing old result.
expect_repl_not_contains $'let x = 9\n:clear\nx + 1\n:quit\n' $'with> 10'

# Non-happy-path: invalid input should not crash REPL session.
expect_repl_contains $'let =\n:quit\n' 'Goodbye!'

if [[ "$failures" -ne 0 ]]; then
  echo "phase6 repl tests: $failures failure(s)"
  exit 1
fi

echo "phase6 repl tests: PASS"
