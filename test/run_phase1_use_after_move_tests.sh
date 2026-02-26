#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase1 use-after-move tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_fail_with_msg() {
  local file="$1"
  local msg="$2"
  local out
  if out=$("$WITH_BIN" check "$file" 2>&1 >/dev/null); then
    echo "FAIL(use-after-move) $file"
    failures=$((failures + 1))
    return
  fi
  if [[ "$out" != *"$msg"* ]]; then
    echo "FAIL(use-after-move-msg) $file"
    failures=$((failures + 1))
    return
  fi
  echo "PASS(use-after-move) $file"
}

cat >"$tmpdir/use_after_move_let.w" <<'EOF1'
type Res = { v: i32 }

fn Res.drop(self: Res) -> void =
    let _cleanup = self.v

fn main() -> i32 =
    let r1 = Res { v: 1 }
    let _r2 = r1
    let x = r1.v
    if x == 1 then 0 else 1
EOF1
expect_fail_with_msg "$tmpdir/use_after_move_let.w" "use of moved value"

cat >"$tmpdir/use_after_move_assign.w" <<'EOF2'
type Res = { v: i32 }

fn Res.drop(self: Res) -> void =
    let _cleanup = self.v

fn main() -> i32 =
    var a = Res { v: 2 }
    var b = Res { v: 3 }
    b = a
    let y = a.v
    if y == 2 then 0 else 1
EOF2
expect_fail_with_msg "$tmpdir/use_after_move_assign.w" "use of moved value"

if [[ "$failures" -ne 0 ]]; then
  echo "phase1 use-after-move tests: $failures failure(s)"
  exit 1
fi

echo "phase1 use-after-move tests: PASS"
