#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 pattern-variants tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(pattern-variants-run) $file"
  else
    echo "FAIL(pattern-variants-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(pattern-variants-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(pattern-variants-fail) $file"
  fi
}

cat >"$tmpdir/pattern_variants_ok.w" <<'EOF1'
type Shape = Circle(i32) | Rect(i32, i32) | Point
type Wrapped = Wrap(Shape) | Empty

fn literal_or_wildcard(n: i32) -> i32 =
    match n
        0 -> 0
        1 | 2 -> 10
        _ -> -1

fn binding_value(n: i32) -> i32 =
    match n
        value -> value + 1

fn score_shape(s: Shape) -> i32 =
    match s
        whole @ Rect(w, h) if w == h -> if whole.is_Rect() then w * 10 else 0
        Circle(r) -> r + 1
        Point -> 0
        _ -> 1

fn nested_eval(w: Wrapped) -> i32 =
    match w
        Wrap(inner) ->
            match inner
                Circle(r) -> r
                Rect(w, h) -> w + h
                Point -> 0
        Empty -> -1

fn main() -> i32 =
    let ok =
        literal_or_wildcard(0) == 0 and
        literal_or_wildcard(2) == 10 and
        literal_or_wildcard(-4) == -1 and
        binding_value(7) == 8 and
        score_shape(Rect(3, 3)) == 30 and
        score_shape(Circle(4)) == 5 and
        score_shape(Point) == 0 and
        nested_eval(Wrap(Rect(2, 4))) == 6 and
        nested_eval(Empty) == -1
    if ok then 0 else 1
EOF1
expect_run_pass "$tmpdir/pattern_variants_ok.w"

cat >"$tmpdir/pattern_variant_arity_fail.w" <<'EOF2'
type Shape = Circle(i32) | Point

fn main() -> i32 =
    let s = Circle(1)
    let _v = match s
        Circle(a, b) -> a + b
        Point -> 0
    0
EOF2
expect_check_fail "$tmpdir/pattern_variant_arity_fail.w"

cat >"$tmpdir/pattern_variant_wrong_enum_fail.w" <<'EOF3'
type A = One | Two
type B = Bee

fn main() -> i32 =
    let x = Bee
    let _v = match x
        One -> 1
        _ -> 0
    0
EOF3
expect_check_fail "$tmpdir/pattern_variant_wrong_enum_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 pattern-variants tests: $failures failure(s)"
  exit 1
fi

echo "phase2 pattern-variants tests: PASS"
