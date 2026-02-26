#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 monomorphization tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(mono-run) $file"
  else
    echo "FAIL(mono-run) $file"
    failures=$((failures + 1))
  fi
}

expect_ir_has() {
  local file="$1"
  local needle="$2"
  local ir
  if ! ir=$("$WITH_BIN" ir "$file" 2>/dev/null); then
    echo "FAIL(mono-ir) $file"
    failures=$((failures + 1))
    return
  fi
  if [[ "$ir" != *"$needle"* ]]; then
    echo "FAIL(mono-ir-missing) $file"
    failures=$((failures + 1))
    return
  fi
  echo "PASS(mono-ir) $file"
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(mono-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(mono-fail) $file"
  fi
}

cat >"$tmpdir/mono_multi_types.w" <<'EOF1'
fn id[T](x: T) -> T =
    x

fn main() -> i32 =
    let a = id(41)
    let b = id(true)
    if a == 41 and b then 0 else 1
EOF1
expect_run_pass "$tmpdir/mono_multi_types.w"
expect_ir_has "$tmpdir/mono_multi_types.w" "@id__i32"
expect_ir_has "$tmpdir/mono_multi_types.w" "@id__bool"

cat >"$tmpdir/mono_uninferred_fail.w" <<'EOF2'
fn make[T]() -> T =
    0

fn main() -> i32 =
    let _x = make()
    0
EOF2
expect_check_fail "$tmpdir/mono_uninferred_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 monomorphization tests: $failures failure(s)"
  exit 1
fi

echo "phase2 monomorphization tests: PASS"
