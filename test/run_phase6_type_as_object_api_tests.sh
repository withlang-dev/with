#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase6 type-as-object API tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(type-object-run) $file"
  else
    echo "FAIL(type-object-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(type-object-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(type-object-run-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

# Existing broad type-object + comptime cascade coverage.
expect_run_pass "test/cases/comptime_cascade_type_api.w"

# Positive: enum variants + primitive/object metadata.
cat >"$tmpdir/type_object_enum_primitive_ok.w" <<'EOF1'
type Color = Red | Green | Blue
type Point = { x: i32, y: i32 }

fn main() -> i32 =
    assert(Color.variants().len() == 3)
    assert(Point.fields().len() == 2)
    assert(i32.name() == "i32")
    assert(i32.size() > 0)
    assert(i32.align() > 0)
    assert(i32.is_copy())
    0
EOF1
expect_run_pass "$tmpdir/type_object_enum_primitive_ok.w"

# Positive: generic type-parameter object API in comptime fn context.
cat >"$tmpdir/type_object_generic_ok.w" <<'EOF2'
type Pair = { a: i32, b: i32 }

comptime fn field_count[T: type](x: T) -> i32 =
    let fs = T.fields()
    fs.len() as i32

fn main() -> i32 =
    let p = Pair { a: 1, b: 2 }
    assert(field_count(p) == 2)
    0
EOF2
expect_run_pass "$tmpdir/type_object_generic_ok.w"

# Non-happy-path: type-object API with invalid arity.
cat >"$tmpdir/type_object_bad_arity_fail.w" <<'EOF3'
type Point = { x: i32 }

fn main() -> i32 =
    let _ = Point.fields(1)
    0
EOF3
expect_run_fail "$tmpdir/type_object_bad_arity_fail.w"

# Non-happy-path: value is not a type object.
cat >"$tmpdir/type_object_value_receiver_fail.w" <<'EOF4'
type Point = { x: i32 }

fn main() -> i32 =
    let p = Point { x: 1 }
    let _ = p.fields()
    0
EOF4
expect_run_fail "$tmpdir/type_object_value_receiver_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase6 type-as-object API tests: $failures failure(s)"
  exit 1
fi

echo "phase6 type-as-object API tests: PASS"
