#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for raw-pointer as_option tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(as_option-run) $file"
  else
    echo "FAIL(as_option-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(as_option-negative) $file"
    failures=$((failures + 1))
  else
    echo "PASS(as_option-negative) $file"
  fi
}

# Non-null mapping: malloc pointer should map to Some.
cat >"$tmpdir/as_option_non_null.w" <<'EOF'
use c_import("#include <stdlib.h>")

fn main() -> i32 =
    let p = malloc(8)
    let o = p.as_option()
    if o.is_none() then return 1
    free(p)
    0
EOF
expect_run_pass "$tmpdir/as_option_non_null.w"

# Null mapping: null raw pointer should map to None.
cat >"$tmpdir/as_option_null.w" <<'EOF'
use c_import("#include <string.h>")

fn main() -> i32 =
    let p = strchr(c"abc", 122)
    let o = p.as_option()
    if o.is_none() then 0 else 1
EOF
expect_run_pass "$tmpdir/as_option_null.w"

# Negative: as_option on non-pointer must fail.
cat >"$tmpdir/as_option_non_pointer.w" <<'EOF'
fn main() -> i32 =
    let x = 1
    let _ = x.as_option()
    0
EOF
expect_check_fail "$tmpdir/as_option_non_pointer.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase0 raw-pointer as_option tests: $failures failure(s)"
  exit 1
fi

echo "phase0 raw-pointer as_option tests: PASS"
