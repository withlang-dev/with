#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for c_import milestone tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(c_import-milestone-run) $file"
  else
    echo "FAIL(c_import-milestone-run) $file"
    failures=$((failures + 1))
  fi
}

expect_build_fail() {
  local file="$1"
  if "$WITH_BIN" build "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(c_import-milestone-negative) $file"
    failures=$((failures + 1))
  else
    echo "PASS(c_import-milestone-negative) $file"
  fi
}

cat >"$tmpdir/c_import_stdio_milestone.w" <<'EOF1'
use c_import("#include <stdio.h>")

fn main -> i32:
    puts(c"milestone puts")
    printf(c"milestone printf %d\n", 42)
    0
EOF1
expect_run_pass "$tmpdir/c_import_stdio_milestone.w"

cat >"$tmpdir/c_import_stdio_negative.w" <<'EOF2'
use c_import("#include <stdio.h>")

fn main -> i32:
    if no_such_stdio_symbol() == 0 then 0 else 1
EOF2
expect_build_fail "$tmpdir/c_import_stdio_negative.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase0 c_import milestone tests: $failures failure(s)"
  exit 1
fi

echo "phase0 c_import milestone tests: PASS"
