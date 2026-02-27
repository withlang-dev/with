#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase1 copy/drop exclusivity tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "PASS(copy-drop-pass) $file"
  else
    echo "FAIL(copy-drop-pass) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail_msg() {
  local file="$1"
  local msg="$2"
  local out
  if out=$("$WITH_BIN" check "$file" 2>&1 >/dev/null); then
    echo "FAIL(copy-drop-fail) $file"
    failures=$((failures + 1))
    return
  fi
  if [[ "$out" != *"$msg"* ]]; then
    echo "FAIL(copy-drop-msg) $file"
    failures=$((failures + 1))
    return
  fi
  echo "PASS(copy-drop-fail) $file"
}

cat >"$tmpdir/copy_only_ok.w" <<'EOF1'
@[derive(Copy)]
type Point = { x: i32, y: i32 }

fn main -> i32:
    let p1 = Point { x: 1, y: 2 }
    let p2 = p1
    if p1.x + p2.x == 2 then 0 else 1
EOF1
expect_check_pass "$tmpdir/copy_only_ok.w"

cat >"$tmpdir/copy_drop_conflict.w" <<'EOF2'
@[derive(Copy)]
type Res = { v: i32 }

fn Res.drop(self: Res) -> void:
    let _cleanup = self.v

fn main -> i32:
    0
EOF2
expect_check_fail_msg "$tmpdir/copy_drop_conflict.w" "type cannot be both Copy and Drop"

cat >"$tmpdir/derive_copy_obvious_noncopy.w" <<'EOF3'
@[derive(Copy)]
type Buffer = { data: Vec[u8] }

fn main -> i32:
    0
EOF3
expect_check_fail_msg "$tmpdir/derive_copy_obvious_noncopy.w" "cannot derive Copy"

if [[ "$failures" -ne 0 ]]; then
  echo "phase1 copy/drop exclusivity tests: $failures failure(s)"
  exit 1
fi

echo "phase1 copy/drop exclusivity tests: PASS"
