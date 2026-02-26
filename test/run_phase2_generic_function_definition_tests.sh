#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 generic-function-definition tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(generic-fn-run) $file"
  else
    echo "FAIL(generic-fn-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(generic-fn-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(generic-fn-fail) $file"
  fi
}

cat >"$tmpdir/generic_fn_ok.w" <<'EOF1'
fn id[T](x: T) -> T:
    x

fn pair_first[T, U](x: T, y: U) -> T:
    x

fn main -> i32:
    let a = id(40)
    let b = id(true)
    let c = pair_first(2, 99)
    if a == 40 and b and c == 2 then 0 else 1
EOF1
expect_run_pass "$tmpdir/generic_fn_ok.w"

cat >"$tmpdir/generic_fn_unknown_type_fail.w" <<'EOF2'
fn bad[T](x: U) -> T:
    x

fn main -> i32:
    0
EOF2
expect_check_fail "$tmpdir/generic_fn_unknown_type_fail.w"

cat >"$tmpdir/generic_fn_syntax_fail.w" <<'EOF3'
fn bad[T(x: T) -> T =
    x

fn main -> i32:
    0
EOF3
expect_check_fail "$tmpdir/generic_fn_syntax_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 generic-function-definition tests: $failures failure(s)"
  exit 1
fi

echo "phase2 generic-function-definition tests: PASS"
