#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase1 drop-order tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_output() {
  local file="$1"
  local expected="$2"
  local out
  if ! out=$("$WITH_BIN" run "$file" 2>/dev/null); then
    echo "FAIL(drop-run) $file"
    failures=$((failures + 1))
    return
  fi
  if [[ "$out" != "$expected" ]]; then
    echo "FAIL(drop-output) $file"
    failures=$((failures + 1))
    return
  fi
  echo "PASS(drop-output) $file"
}

cat >"$tmpdir/drop_scope_order.w" <<'EOF1'
type A = { id: i32 }
type B = { id: i32 }

fn A.drop(self: A) -> void =
    println("drop A")

fn B.drop(self: B) -> void =
    println("drop B")

fn scope_drop_order() -> i32 =
    let a = A { id: 1 }
    let b = B { id: 2 }
    println("in scope")
    0

fn main() -> i32 =
    scope_drop_order()
    println("after scope")
    0
EOF1
expect_run_output "$tmpdir/drop_scope_order.w" $'in scope\ndrop B\ndrop A\nafter scope'

cat >"$tmpdir/drop_early_return_order.w" <<'EOF2'
type A = { id: i32 }
type B = { id: i32 }

fn A.drop(self: A) -> void =
    println("drop A")

fn B.drop(self: B) -> void =
    println("drop B")

fn early_scope() -> i32 =
    let a = A { id: 1 }
    let b = B { id: 2 }
    println("in early")
    return 0

fn main() -> i32 =
    early_scope()
    println("after early")
    0
EOF2
expect_run_output "$tmpdir/drop_early_return_order.w" $'in early\ndrop B\ndrop A\nafter early'

if [[ "$failures" -ne 0 ]]; then
  echo "phase1 drop-order tests: $failures failure(s)"
  exit 1
fi

echo "phase1 drop-order tests: PASS"
