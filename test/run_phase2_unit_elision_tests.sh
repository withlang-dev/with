#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 unit-elision tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(unit-elision-run) $file"
  else
    echo "FAIL(unit-elision-run) $file"
    failures=$((failures + 1))
  fi
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(unit-elision-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(unit-elision-run-fail) $file"
  fi
}

cat >"$tmpdir/unit_elision_ok_ctor_ok.w" <<'EOF1'
fn noop() -> Result[Unit, i32] =
    Ok()

fn main() -> i32 =
    let r = noop()
    if r.is_ok() then 0 else 1
EOF1
expect_run_pass "$tmpdir/unit_elision_ok_ctor_ok.w"

cat >"$tmpdir/unit_elision_ctor_branching_ok.w" <<'EOF2'
fn make(ok: bool) -> Result[Unit, i32] =
    if ok then Ok() else Err(1)

fn main() -> i32 =
    let r1 = make(true)
    let r2 = make(false)
    if r1.is_ok() and r2.is_err() then 0 else 1
EOF2
expect_run_pass "$tmpdir/unit_elision_ctor_branching_ok.w"

cat >"$tmpdir/unit_elision_unwrap_or_result_ok.w" <<'EOF3'
fn main() -> i32 =
    let r: Result[Unit, i32] = Err(7)
    let _u = r.unwrap_or()
    0
EOF3
expect_run_pass "$tmpdir/unit_elision_unwrap_or_result_ok.w"

cat >"$tmpdir/unit_elision_unwrap_or_option_ok.w" <<'EOF4'
fn main() -> i32 =
    let o: Option[Unit] = None
    let _u = o.unwrap_or()
    0
EOF4
expect_run_pass "$tmpdir/unit_elision_unwrap_or_option_ok.w"

cat >"$tmpdir/unit_elision_ok_no_args_non_unit_fail.w" <<'EOF5'
fn bad() -> Result[str, i32] =
    Ok()

fn main() -> i32 = 0
EOF5
expect_run_fail "$tmpdir/unit_elision_ok_no_args_non_unit_fail.w"

cat >"$tmpdir/unit_elision_unwrap_or_non_unit_fail.w" <<'EOF6'
fn main() -> i32 =
    let r: Result[str, i32] = Err(1)
    let _x = r.unwrap_or()
    0
EOF6
expect_run_fail "$tmpdir/unit_elision_unwrap_or_non_unit_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 unit-elision tests: $failures failure(s)"
  exit 1
fi

echo "phase2 unit-elision tests: PASS"
