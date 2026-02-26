#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for tuple tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "PASS(tuple-pass) $file"
  else
    echo "FAIL(tuple-pass) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(tuple-negative) $file"
    failures=$((failures + 1))
  else
    echo "PASS(tuple-negative) $file"
  fi
}

cat >"$tmpdir/tuple_ok.w" <<'EOF'
fn main -> i32:
    let t = (1, 2)
    let a = t.0
    let b = t.1
    let (x, y) = t
    a + b + x + y
EOF
expect_check_pass "$tmpdir/tuple_ok.w"

cat >"$tmpdir/tuple_oob_index.w" <<'EOF'
fn main -> i32:
    let t = (1, 2)
    t.2
EOF
expect_check_fail "$tmpdir/tuple_oob_index.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase0 tuple tests: $failures failure(s)"
  exit 1
fi

echo "phase0 tuple tests: PASS"

