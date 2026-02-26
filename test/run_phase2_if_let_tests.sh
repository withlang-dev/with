#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 if-let tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(if-let-run) $file"
  else
    echo "FAIL(if-let-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(if-let-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(if-let-fail) $file"
  fi
}

cat >"$tmpdir/if_let_basic_ok.w" <<'EOF1'
type Shape = Circle(i32) | Square(i32) | Point

fn area(s: Shape) -> i32 =
    if let Circle(r) = s:
        r * r
    else
        if let Square(side) = s:
            side * side
        else
            0

fn main() -> i32 =
    if area(Circle(3)) == 9 and area(Square(4)) == 16 and area(Point) == 0 then 0 else 1
EOF1
expect_run_pass "$tmpdir/if_let_basic_ok.w"

cat >"$tmpdir/if_let_no_else_ok.w" <<'EOF2'
type Flag = On | Off

fn main() -> i32 =
    let v = if let On = On:
        7
    v - 7
EOF2
expect_run_pass "$tmpdir/if_let_no_else_ok.w"

cat >"$tmpdir/if_let_bad_pattern_fail.w" <<'EOF3'
type Shape = Circle(i32) | Point

fn main() -> i32 =
    let _v = if let Circle(a, b) = Circle(1):
        a + b
    else
        0
    0
EOF3
expect_check_fail "$tmpdir/if_let_bad_pattern_fail.w"

cat >"$tmpdir/if_let_syntax_fail.w" <<'EOF4'
type Shape = Circle(i32) | Point

fn main() -> i32 =
    let _v = if let Circle(x) Circle(1):
        x
    else
        0
    0
EOF4
expect_check_fail "$tmpdir/if_let_syntax_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 if-let tests: $failures failure(s)"
  exit 1
fi

echo "phase2 if-let tests: PASS"
