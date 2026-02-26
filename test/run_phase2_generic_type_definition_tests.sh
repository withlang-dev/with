#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 generic-type-definition tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "PASS(generic-type-pass) $file"
  else
    echo "FAIL(generic-type-pass) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(generic-type-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(generic-type-fail) $file"
  fi
}

cat >"$tmpdir/generic_type_struct_ok.w" <<'EOF1'
type Pair[T, U] = {
    left: T,
    right: U,
}

fn main() -> i32 =
    0
EOF1
expect_check_pass "$tmpdir/generic_type_struct_ok.w"

cat >"$tmpdir/generic_type_alias_ok.w" <<'EOF2'
type Wrapper[T] = T

fn main() -> i32 =
    0
EOF2
expect_check_pass "$tmpdir/generic_type_alias_ok.w"

cat >"$tmpdir/generic_type_unknown_param_fail.w" <<'EOF3'
type Bad[T] = {
    value: U,
}

fn main() -> i32 =
    0
EOF3
expect_check_fail "$tmpdir/generic_type_unknown_param_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 generic-type-definition tests: $failures failure(s)"
  exit 1
fi

echo "phase2 generic-type-definition tests: PASS"
