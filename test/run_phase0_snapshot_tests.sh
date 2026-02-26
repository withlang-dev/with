#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for snapshot tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_pass() {
  local cmd=("$@")
  if "${cmd[@]}" >/dev/null 2>/dev/null; then
    echo "PASS(snapshot-pass) ${cmd[*]}"
  else
    echo "FAIL(snapshot-pass) ${cmd[*]}"
    failures=$((failures + 1))
  fi
}

expect_fail() {
  local cmd=("$@")
  if "${cmd[@]}" >/dev/null 2>/dev/null; then
    echo "FAIL(snapshot-fail) ${cmd[*]}"
    failures=$((failures + 1))
  else
    echo "PASS(snapshot-fail) ${cmd[*]}"
  fi
}

cat >"$tmpdir/snap_case.w" <<'EOF'
fn main() -> i32 =
    println("v1")
    0
EOF

# 1) Create snapshot.
expect_pass "$WITH_BIN" test "$tmpdir/snap_case.w" --update

# 2) Snapshot should now pass without update.
expect_pass "$WITH_BIN" test "$tmpdir/snap_case.w"

# 3) Change output and ensure mismatch fails without update.
cat >"$tmpdir/snap_case.w" <<'EOF'
fn main() -> i32 =
    println("v2")
    0
EOF
expect_fail "$WITH_BIN" test "$tmpdir/snap_case.w"

# 4) Update snapshot and verify it passes.
expect_pass "$WITH_BIN" test "$tmpdir/snap_case.w" --update
expect_pass "$WITH_BIN" test "$tmpdir/snap_case.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase0 snapshot tests: $failures failure(s)"
  exit 1
fi

echo "phase0 snapshot tests: PASS"

