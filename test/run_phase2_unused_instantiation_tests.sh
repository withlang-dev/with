#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 unused-instantiation tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_ir_contains() {
  local file="$1"
  local needle="$2"
  local ir
  if ! ir=$("$WITH_BIN" ir "$file" 2>/dev/null); then
    echo "FAIL(unused-inst-ir) $file"
    failures=$((failures + 1))
    return
  fi
  if [[ "$ir" != *"$needle"* ]]; then
    echo "FAIL(unused-inst-missing) $file"
    failures=$((failures + 1))
    return
  fi
  echo "PASS(unused-inst-has) $file"
}

expect_ir_not_contains() {
  local file="$1"
  local needle="$2"
  local ir
  if ! ir=$("$WITH_BIN" ir "$file" 2>/dev/null); then
    echo "FAIL(unused-inst-ir) $file"
    failures=$((failures + 1))
    return
  fi
  if [[ "$ir" == *"$needle"* ]]; then
    echo "FAIL(unused-inst-unexpected) $file"
    failures=$((failures + 1))
    return
  fi
  echo "PASS(unused-inst-not) $file"
}

cat >"$tmpdir/unused_generic.w" <<'EOF1'
fn id[T](x: T) -> T =
    x

fn main() -> i32 =
    0
EOF1
expect_ir_not_contains "$tmpdir/unused_generic.w" "@id__"

cat >"$tmpdir/single_instantiation.w" <<'EOF2'
fn id[T](x: T) -> T =
    x

fn main() -> i32 =
    id(7)
EOF2
expect_ir_contains "$tmpdir/single_instantiation.w" "@id__i32"
expect_ir_not_contains "$tmpdir/single_instantiation.w" "@id__bool"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 unused-instantiation tests: $failures failure(s)"
  exit 1
fi

echo "phase2 unused-instantiation tests: PASS"
