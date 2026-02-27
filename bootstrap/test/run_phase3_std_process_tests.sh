#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase3 std.process tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(process-check) $file"
  else
    echo "FAIL(process-check) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(process-run) $file"
  else
    echo "FAIL(process-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(process-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(process-run-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_pass "lib/std/process.w"
expect_run_pass "bootstrap/test/cases/import_std_process.w"

cat >"$tmpdir/std_process_extended_ok.w" <<'EOF1'
use std.process

fn main -> i32:
    assert(pid() > 0)

    let argv = args()
    assert(argv.len() >= 0)

    assert(set_env("WITH_STD_PROCESS_EXT", "yes") == 0)
    let ev = env("WITH_STD_PROCESS_EXT")
    assert(ev.is_some())
    assert(ev.unwrap() == "yes")

    let missing = env("__WITH_STD_PROCESS_NEVER_SET__")
    assert(missing.is_none())

    assert(system_cmd("true") == 0)
    let ok_cmd = command("true")
    assert(ok_cmd.run() == 0)
    assert(ok_cmd.status() == 0)

    let bad_cmd = command("false")
    assert(bad_cmd.status() != 0)
EOF1
expect_run_pass "$tmpdir/std_process_extended_ok.w"

cat >"$tmpdir/std_process_pid_arity_fail.w" <<'EOF2'
use std.process

fn main -> i32:
    let _p = pid(1)
EOF2
expect_run_fail "$tmpdir/std_process_pid_arity_fail.w"

cat >"$tmpdir/std_process_args_arity_fail.w" <<'EOF3'
use std.process

fn main -> i32:
    let _a = args(1)
EOF3
expect_run_fail "$tmpdir/std_process_args_arity_fail.w"

cat >"$tmpdir/std_process_env_type_fail.w" <<'EOF4'
use std.process

fn main -> i32:
    let _e = env(1)
EOF4
expect_run_fail "$tmpdir/std_process_env_type_fail.w"

cat >"$tmpdir/std_process_set_env_arity_fail.w" <<'EOF5'
use std.process

fn main -> i32:
    let _x = set_env("ONLY_ONE_ARG")
EOF5
expect_run_fail "$tmpdir/std_process_set_env_arity_fail.w"

cat >"$tmpdir/std_process_command_arity_fail.w" <<'EOF6'
use std.process

fn main -> i32:
    let _c = command()
EOF6
expect_run_fail "$tmpdir/std_process_command_arity_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase3 std.process tests: $failures failure(s)"
  exit 1
fi

echo "phase3 std.process tests: PASS"
