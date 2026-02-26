#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 closure-parse-forms tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(closure-parse-run) $file"
  else
    echo "FAIL(closure-parse-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(closure-parse-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(closure-parse-fail) $file"
  fi
}

cat >"$tmpdir/closure_inline_ok.w" <<'EOF1'
fn apply(f: fn(i32) -> i32, x: i32) -> i32 =
    f(x)

fn main() -> i32 =
    let inc = |x| x + 1
    if apply(inc, 4) == 5 then 0 else 1
EOF1
expect_run_pass "$tmpdir/closure_inline_ok.w"

cat >"$tmpdir/closure_block_ok.w" <<'EOF2'
fn apply(f: fn(i32) -> i32, x: i32) -> i32 =
    f(x)

fn main() -> i32 =
    let dbl = |x|:
        let y = x + x
        y
    if apply(dbl, 3) == 6 then 0 else 1
EOF2
expect_run_pass "$tmpdir/closure_block_ok.w"

cat >"$tmpdir/closure_missing_pipe_fail.w" <<'EOF3'
fn main() -> i32 =
    let bad = |x x + 1
    bad(1)
EOF3
expect_check_fail "$tmpdir/closure_missing_pipe_fail.w"

cat >"$tmpdir/closure_bad_param_fail.w" <<'EOF4'
fn main() -> i32 =
    let bad = |1| 1
    bad()
EOF4
expect_check_fail "$tmpdir/closure_bad_param_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 closure-parse-forms tests: $failures failure(s)"
  exit 1
fi

echo "phase2 closure-parse-forms tests: PASS"
