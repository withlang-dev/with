#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 usefulness tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_build_warn_msg() {
  local file="$1"
  local msg="$2"
  local stderr_file="$tmpdir/stderr.warn.$$"
  if "$WITH_BIN" build "$file" >/dev/null 2>"$stderr_file"; then
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(usefulness-warn) $file"
    else
      echo "FAIL(usefulness-warn-msg) $file"
      failures=$((failures + 1))
    fi
  else
    echo "FAIL(usefulness-build) $file"
    failures=$((failures + 1))
  fi
  rm -f "$stderr_file"
}

expect_build_no_warn() {
  local file="$1"
  local stderr_file="$tmpdir/stderr.nowarn.$$"
  if "$WITH_BIN" build "$file" >/dev/null 2>"$stderr_file"; then
    if grep -Fqi "unreachable match arm" "$stderr_file"; then
      echo "FAIL(usefulness-nowarn) $file"
      failures=$((failures + 1))
    else
      echo "PASS(usefulness-nowarn) $file"
    fi
  else
    echo "FAIL(usefulness-build) $file"
    failures=$((failures + 1))
  fi
  rm -f "$stderr_file"
}

cat >"$tmpdir/usefulness_reachable_ok.w" <<'EOF1'
type E = A | B | C

fn f(e: E) -> i32:
    match e
        A -> 1
        B -> 2
        _ -> 3

fn main -> i32: f(A)
EOF1
expect_build_no_warn "$tmpdir/usefulness_reachable_ok.w"

cat >"$tmpdir/usefulness_after_wildcard_warn.w" <<'EOF2'
fn f(x: i32) -> i32:
    match x
        _ -> 0
        1 -> 1

fn main -> i32: f(1)
EOF2
expect_build_warn_msg "$tmpdir/usefulness_after_wildcard_warn.w" "unreachable match arm: previous arm covers all remaining values"

cat >"$tmpdir/usefulness_duplicate_literal_warn.w" <<'EOF3'
fn f(x: i32) -> i32:
    match x
        1 -> 10
        1 -> 20
        _ -> 30

fn main -> i32: f(1)
EOF3
expect_build_warn_msg "$tmpdir/usefulness_duplicate_literal_warn.w" "unreachable match arm"

cat >"$tmpdir/usefulness_duplicate_variant_warn.w" <<'EOF4'
type E = A | B

fn f(e: E) -> i32:
    match e
        A -> 1
        A -> 2
        B -> 3

fn main -> i32: f(A)
EOF4
expect_build_warn_msg "$tmpdir/usefulness_duplicate_variant_warn.w" "unreachable match arm"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 usefulness tests: $failures failure(s)"
  exit 1
fi

echo "phase2 usefulness tests: PASS"
