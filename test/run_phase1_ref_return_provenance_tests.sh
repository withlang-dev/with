#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase1 ref-return provenance tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "PASS(ref-return-pass) $file"
  else
    echo "FAIL(ref-return-pass) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail_msg() {
  local file="$1"
  local msg="$2"
  local out
  if out=$("$WITH_BIN" check "$file" 2>&1 >/dev/null); then
    echo "FAIL(ref-return-fail) $file"
    failures=$((failures + 1))
    return
  fi
  if [[ "$out" != *"$msg"* ]]; then
    echo "FAIL(ref-return-msg) $file"
    failures=$((failures + 1))
    return
  fi
  echo "PASS(ref-return-fail) $file"
}

cat >"$tmpdir/ref_return_fail.w" <<'EOF1'
fn id_ref(x: &i32) -> &i32 =
    x

fn main() -> i32 =
    0
EOF1
expect_check_fail_msg "$tmpdir/ref_return_fail.w" "ephemeral references cannot be returned from functions"

cat >"$tmpdir/ref_return_ok_value.w" <<'EOF2'
fn id_val(x: i32) -> i32 =
    x

fn main() -> i32 =
    id_val(7)
EOF2
expect_check_pass "$tmpdir/ref_return_ok_value.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase1 ref-return provenance tests: $failures failure(s)"
  exit 1
fi

echo "phase1 ref-return provenance tests: PASS"
