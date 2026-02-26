#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for range tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "PASS(range-pass) $file"
  else
    echo "FAIL(range-pass) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(range-negative) $file"
    failures=$((failures + 1))
  else
    echo "PASS(range-negative) $file"
  fi
}

cat >"$tmpdir/range_ok.w" <<'EOF'
fn main() -> i32 =
    let ex = 0..10
    let inc = 0..=10
    for x in ex:
        let _ = x
    for y in inc:
        let _ = y
    0
EOF
expect_check_pass "$tmpdir/range_ok.w"

cat >"$tmpdir/range_bad_start.w" <<'EOF'
fn main() -> i32 =
    let r = "a"..10
    0
EOF
expect_check_fail "$tmpdir/range_bad_start.w"

cat >"$tmpdir/range_bad_end.w" <<'EOF'
fn main() -> i32 =
    let r = 0..false
    0
EOF
expect_check_fail "$tmpdir/range_bad_end.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase0 range tests: $failures failure(s)"
  exit 1
fi

echo "phase0 range tests: PASS"

