#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 exhaustiveness tests..."
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
      echo "PASS(exhaustiveness-warn) $file"
    else
      echo "FAIL(exhaustiveness-warn-msg) $file"
      failures=$((failures + 1))
    fi
  else
    echo "FAIL(exhaustiveness-build) $file"
    failures=$((failures + 1))
  fi
  rm -f "$stderr_file"
}

expect_build_no_warn() {
  local file="$1"
  local stderr_file="$tmpdir/stderr.nowarn.$$"
  if "$WITH_BIN" build "$file" >/dev/null 2>"$stderr_file"; then
    if grep -Fqi "non-exhaustive match" "$stderr_file"; then
      echo "FAIL(exhaustiveness-nowarn) $file"
      failures=$((failures + 1))
    else
      echo "PASS(exhaustiveness-nowarn) $file"
    fi
  else
    echo "FAIL(exhaustiveness-build) $file"
    failures=$((failures + 1))
  fi
  rm -f "$stderr_file"
}

cat >"$tmpdir/exhaustive_enum_ok.w" <<'EOF1'
type Dir = Up | Down | Left | Right

fn score(d: Dir) -> i32 =
    match d
        Up -> 1
        Down -> 2
        Left -> 3
        Right -> 4

fn main() -> i32 = score(Up)
EOF1
expect_build_no_warn "$tmpdir/exhaustive_enum_ok.w"

cat >"$tmpdir/non_exhaustive_enum_warn.w" <<'EOF2'
type Dir = Up | Down | Left | Right

fn score(d: Dir) -> i32 =
    match d
        Up -> 1
        Down -> 2
        _ -> 9

fn main() -> i32 = score(Up)
EOF2
expect_build_no_warn "$tmpdir/non_exhaustive_enum_warn.w"

cat >"$tmpdir/non_exhaustive_enum_missing_warn.w" <<'EOF3'
type Dir = Up | Down | Left | Right

fn score(d: Dir) -> i32 =
    match d
        Up -> 1
        Down -> 2

fn main() -> i32 = score(Up)
EOF3
expect_build_warn_msg "$tmpdir/non_exhaustive_enum_missing_warn.w" "non-exhaustive match: missing variant"

cat >"$tmpdir/non_exhaustive_bool_warn.w" <<'EOF4'
fn score(v: bool) -> i32 =
    match v
        true -> 1

fn main() -> i32 = score(true)
EOF4
expect_build_warn_msg "$tmpdir/non_exhaustive_bool_warn.w" "non-exhaustive match on bool"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 exhaustiveness tests: $failures failure(s)"
  exit 1
fi

echo "phase2 exhaustiveness tests: PASS"
