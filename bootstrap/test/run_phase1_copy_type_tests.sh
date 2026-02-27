#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase1 copy-type tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "PASS(copy-pass) $file"
  else
    echo "FAIL(copy-pass) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(copy-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(copy-fail) $file"
  fi
}

cat >"$tmpdir/copy_i32.w" <<'EOF1'
fn main -> i32:
    let a: i32 = 10
    let b = a
    if a + b == 20 then 0 else 1
EOF1
expect_check_pass "$tmpdir/copy_i32.w"

cat >"$tmpdir/copy_struct.w" <<'EOF2'
type Point = { x: i32, y: i32 }

fn main -> i32:
    let p1 = Point { x: 1, y: 2 }
    let p2 = p1
    if p1.x + p2.x == 2 then 0 else 1
EOF2
expect_check_pass "$tmpdir/copy_struct.w"

cat >"$tmpdir/noncopy_drop.w" <<'EOF3'
type Res = { v: i32 }

fn Res.drop(self: Res) -> void:
    let _cleanup = self.v

fn main -> i32:
    let r1 = Res { v: 5 }
    let _r2 = r1
    if r1.v == 5 then 0 else 1
EOF3
expect_check_fail "$tmpdir/noncopy_drop.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase1 copy-type tests: $failures failure(s)"
  exit 1
fi

echo "phase1 copy-type tests: PASS"
