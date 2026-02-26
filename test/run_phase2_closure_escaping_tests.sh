#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 closure-escaping tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(closure-escaping-run) $file"
  else
    echo "FAIL(closure-escaping-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail_msg() {
  local file="$1"
  local msg="$2"
  local out
  if out="$("$WITH_BIN" check "$file" 2>&1 >/dev/null)"; then
    echo "FAIL(closure-escaping-fail) $file"
    failures=$((failures + 1))
    return
  fi
  if grep -Fq "$msg" <<<"$out"; then
    echo "PASS(closure-escaping-fail) $file"
  else
    echo "FAIL(closure-escaping-msg) $file"
    failures=$((failures + 1))
  fi
}

cat >"$tmpdir/closure_nonescaping_ref_capture_ok.w" <<'EOF1'
fn apply(f: fn(i32) -> i32, x: i32) -> i32 =
    f(x)

fn main() -> i32 =
    let x = 10
    let r = &x
    let out = apply(|n| n + *r, 5)
    if out == 15 then 0 else 1
EOF1
expect_run_pass "$tmpdir/closure_nonescaping_ref_capture_ok.w"

cat >"$tmpdir/closure_escaping_ref_capture_fail.w" <<'EOF2'
fn main() -> i32 =
    let x = 10
    let r = &x
    let f = |n| n + *r
    f(1)
EOF2
expect_check_fail_msg "$tmpdir/closure_escaping_ref_capture_fail.w" "closures cannot capture ephemeral references"

cat >"$tmpdir/closure_escaping_no_ref_ok.w" <<'EOF3'
fn main() -> i32 =
    let offset = 3
    let f = |n| n + offset
    if f(2) == 5 then 0 else 1
EOF3
expect_run_pass "$tmpdir/closure_escaping_no_ref_ok.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 closure-escaping tests: $failures failure(s)"
  exit 1
fi

echo "phase2 closure-escaping tests: PASS"
