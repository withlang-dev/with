#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase1 ephemeral-propagation tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_fail_msg() {
  local file="$1"
  local msg="$2"
  local out
  if out=$("$WITH_BIN" check "$file" 2>&1 >/dev/null); then
    echo "FAIL(ephemeral-prop-fail) $file"
    failures=$((failures + 1))
    return
  fi
  if [[ "$out" != *"$msg"* ]]; then
    echo "FAIL(ephemeral-prop-msg) $file"
    failures=$((failures + 1))
    return
  fi
  echo "PASS(ephemeral-prop-fail) $file"
}

cat >"$tmpdir/ephemeral_nested_struct_fail.w" <<'EOF1'
type Bad = { payload: (i32, &i32) }

fn main -> i32:
    0
EOF1
expect_check_fail_msg "$tmpdir/ephemeral_nested_struct_fail.w" "ephemeral references cannot be stored in structs"

cat >"$tmpdir/ephemeral_nested_collection_fail.w" <<'EOF2'
let bad: Vec[(i32, &i32)] = 0

fn main -> i32:
    0
EOF2
expect_check_fail_msg "$tmpdir/ephemeral_nested_collection_fail.w" "ephemeral references cannot be stored in collections"

cat >"$tmpdir/ephemeral_alias_capture_fail.w" <<'EOF3'
fn main -> i32:
    var x: i32 = 1
    let r = &x
    let rr = r
    let f = || *rr
    f()
EOF3
expect_check_fail_msg "$tmpdir/ephemeral_alias_capture_fail.w" "closures cannot capture ephemeral references"

if [[ "$failures" -ne 0 ]]; then
  echo "phase1 ephemeral-propagation tests: $failures failure(s)"
  exit 1
fi

echo "phase1 ephemeral-propagation tests: PASS"
