#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 with-form3 tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(with-form3-run) $file"
  else
    echo "FAIL(with-form3-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(with-form3-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(with-form3-fail) $file"
  fi
}

cat >"$tmpdir/with_form3_binding_ok.w" <<'EOF1'
fn compute(n: i32) -> i32 =
    n * 2

fn main() -> i32 =
    let v = with compute(21) as result:
        result + 1
    if v == 43 then 0 else 1
EOF1
expect_run_pass "$tmpdir/with_form3_binding_ok.w"

cat >"$tmpdir/with_form3_binding_fail.w" <<'EOF2'
fn compute(n: i32) -> i32 =
    n * 2

fn main() -> i32 =
    let _v = with compute(21) as result:
        result + true
    0
EOF2
expect_check_fail "$tmpdir/with_form3_binding_fail.w"

cat >"$tmpdir/with_form3_immutable_binding_fail.w" <<'EOF3'
fn main() -> i32 =
    let _v = with 10 as result:
        result = 11
        result
    0
EOF3
expect_check_fail "$tmpdir/with_form3_immutable_binding_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 with-form3 tests: $failures failure(s)"
  exit 1
fi

echo "phase2 with-form3 tests: PASS"
