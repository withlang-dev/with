#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 pipeline-match tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(pipeline-match-run) $file"
  else
    echo "FAIL(pipeline-match-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(pipeline-match-check-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(pipeline-match-check-fail) $file"
  fi
}

cat >"$tmpdir/pipeline_match_basic_ok.w" <<'EOF1'
fn id(x: i32) -> i32 = x

fn main() -> i32 =
    let v = 2 |> id |> match
        1 -> 10
        2 -> 20
        _ -> 30
    if v == 20 then 0 else 1
EOF1
expect_run_pass "$tmpdir/pipeline_match_basic_ok.w"

cat >"$tmpdir/pipeline_match_chain_ok.w" <<'EOF2'
fn inc(x: i32) -> i32 = x + 1

fn main() -> i32 =
    let out = 1 |> inc |> inc |> match
        3 -> 99
        _ -> 0
    if out == 99 then 0 else 1
EOF2
expect_run_pass "$tmpdir/pipeline_match_chain_ok.w"

cat >"$tmpdir/pipeline_match_guard_ok.w" <<'EOF3'
fn main() -> i32 =
    let v = 5 |> match
        n if n > 3 -> 77
        _ -> 0
    if v == 77 then 0 else 1
EOF3
expect_run_pass "$tmpdir/pipeline_match_guard_ok.w"

cat >"$tmpdir/pipeline_match_missing_arms_fail.w" <<'EOF4'
fn main() -> i32 =
    let v = 1 |> match
    v
EOF4
expect_check_fail "$tmpdir/pipeline_match_missing_arms_fail.w"

cat >"$tmpdir/pipeline_match_bad_arm_fail.w" <<'EOF5'
fn main() -> i32 =
    let v = 1 |> match
        1 => 10
        _ -> 0
    v
EOF5
expect_check_fail "$tmpdir/pipeline_match_bad_arm_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 pipeline-match tests: $failures failure(s)"
  exit 1
fi

echo "phase2 pipeline-match tests: PASS"
