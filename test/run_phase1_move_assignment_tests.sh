#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase1 move-assignment tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "PASS(move-assign-pass) $file"
  else
    echo "FAIL(move-assign-pass) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(move-assign-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(move-assign-fail) $file"
  fi
}

cat >"$tmpdir/move_let_ok.w" <<'EOF1'
type Res = { v: i32 }

fn Res.drop(self: Res) -> void:
    let _cleanup = self.v

fn main -> i32:
    let r1 = Res { v: 1 }
    let r2 = r1
    let r3 = r2
    if r3.v == 1 then 0 else 1
EOF1
expect_check_pass "$tmpdir/move_let_ok.w"

cat >"$tmpdir/move_let_use_after_move.w" <<'EOF2'
type Res = { v: i32 }

fn Res.drop(self: Res) -> void:
    let _cleanup = self.v

fn main -> i32:
    let r1 = Res { v: 1 }
    let _r2 = r1
    let bad = r1.v
    if bad == 1 then 0 else 1
EOF2
expect_check_fail "$tmpdir/move_let_use_after_move.w"

cat >"$tmpdir/move_assign_ok.w" <<'EOF3'
type Res = { v: i32 }

fn Res.drop(self: Res) -> void:
    let _cleanup = self.v

fn main -> i32:
    var a = Res { v: 3 }
    var b = Res { v: 4 }
    b = a
    if b.v == 3 then 0 else 1
EOF3
expect_check_pass "$tmpdir/move_assign_ok.w"

cat >"$tmpdir/move_assign_use_after_move.w" <<'EOF4'
type Res = { v: i32 }

fn Res.drop(self: Res) -> void:
    let _cleanup = self.v

fn main -> i32:
    var a = Res { v: 3 }
    var b = Res { v: 4 }
    b = a
    let bad = a.v
    if bad == 3 then 0 else 1
EOF4
expect_check_fail "$tmpdir/move_assign_use_after_move.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase1 move-assignment tests: $failures failure(s)"
  exit 1
fi

echo "phase1 move-assignment tests: PASS"
