#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 generic-inference tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(generic-infer-run) $file"
  else
    echo "FAIL(generic-infer-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail_msg() {
  local file="$1"
  local msg="$2"
  local out
  if out=$("$WITH_BIN" check "$file" 2>&1 >/dev/null); then
    echo "FAIL(generic-infer-fail) $file"
    failures=$((failures + 1))
    return
  fi
  if [[ "$out" != *"$msg"* ]]; then
    echo "FAIL(generic-infer-msg) $file"
    failures=$((failures + 1))
    return
  fi
  echo "PASS(generic-infer-fail) $file"
}

cat >"$tmpdir/generic_infer_ok.w" <<'EOF1'
fn id[T](x: T) -> T:
    x

fn same[T](a: T, b: T) -> T:
    a

fn main -> i32:
    let a = id(41)
    let b = id(true)
    let c = same(1, 2)
    if a == 41 and b and c == 1 then 0 else 1
EOF1
expect_run_pass "$tmpdir/generic_infer_ok.w"

cat >"$tmpdir/generic_infer_conflict_fail.w" <<'EOF2'
fn same[T](a: T, b: T) -> T:
    a

fn main -> i32:
    let _x = same(1, true)
EOF2
expect_check_fail_msg "$tmpdir/generic_infer_conflict_fail.w" "cannot infer a single type"

cat >"$tmpdir/generic_infer_uninferred_fail.w" <<'EOF3'
fn make[T] -> T:
    0

fn main -> i32:
    let _x = make()
EOF3
expect_check_fail_msg "$tmpdir/generic_infer_uninferred_fail.w" "unknown type"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 generic-inference tests: $failures failure(s)"
  exit 1
fi

echo "phase2 generic-inference tests: PASS"
