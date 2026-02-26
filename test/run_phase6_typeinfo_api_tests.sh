#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase6 TypeInfo API tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(typeinfo-run) $file"
  else
    echo "FAIL(typeinfo-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(typeinfo-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(typeinfo-run-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

# Positive: non-generic TypeInfo equivalent APIs.
cat >"$tmpdir/typeinfo_non_generic_ok.w" <<'EOF1'
type Point = { x: i32, y: i32 }
type Color = Red | Green | Blue

fn main() -> i32 =
    assert(TypeInfo.fields(Point).len() == 2)
    assert(TypeInfo.variants(Color).len() == 3)
    assert(TypeInfo.name(i32) == "i32")
    assert(TypeInfo.size(Point) > 0)
    assert(TypeInfo.align(Point) > 0)
    assert(TypeInfo.is_copy(i32))
    assert(not TypeInfo.implements(Point, Point))
    0
EOF1
expect_run_pass "$tmpdir/typeinfo_non_generic_ok.w"

# Positive: parity between TypeInfo and direct type-object API.
cat >"$tmpdir/typeinfo_parity_ok.w" <<'EOF2'
type Pair = { a: i32, b: i32 }

fn main() -> i32 =
    assert(TypeInfo.fields(Pair).len() == Pair.fields().len())
    assert(TypeInfo.size(Pair) == Pair.size())
    assert(TypeInfo.align(Pair) == Pair.align())
    0
EOF2
expect_run_pass "$tmpdir/typeinfo_parity_ok.w"

# Non-happy-path: value argument is not a type object.
cat >"$tmpdir/typeinfo_value_receiver_fail.w" <<'EOF3'
type Point = { x: i32 }

fn main() -> i32 =
    let p = Point { x: 1 }
    let _ = TypeInfo.fields(p)
    0
EOF3
expect_run_fail "$tmpdir/typeinfo_value_receiver_fail.w"

# Non-happy-path: wrong arity.
cat >"$tmpdir/typeinfo_arity_fail.w" <<'EOF4'
type Point = { x: i32 }

fn main() -> i32 =
    let _ = TypeInfo.size()
    0
EOF4
expect_run_fail "$tmpdir/typeinfo_arity_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase6 TypeInfo API tests: $failures failure(s)"
  exit 1
fi

echo "phase6 TypeInfo API tests: PASS"
