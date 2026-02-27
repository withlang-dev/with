#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase3 ContextError/context tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(context-check) $file"
  else
    echo "FAIL(context-check) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(context-run) $file"
  else
    echo "FAIL(context-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(context-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(context-run-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_stdout() {
  local file="$1"
  local expected="$2"
  local out
  if out=$("$WITH_BIN" run "$file" 2>"$tmpdir/stderr.$$"); then
    if [[ "$out" == "$expected" ]]; then
      echo "PASS(context-run-stdout) $file"
    else
      echo "FAIL(context-run-stdout) $file"
      echo "expected: '$expected'"
      echo "actual:   '$out'"
      failures=$((failures + 1))
    fi
  else
    echo "FAIL(context-run-stdout) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_pass "lib/std/result.w"
expect_run_pass "bootstrap/test/cases/result_try.w"
expect_run_pass "bootstrap/test/cases/result_combinators.w"

cat >"$tmpdir/result_context_ok.w" <<'EOF1'
fn read_ok -> Result[i32, i32]:
    Ok(7)

fn read_err -> Result[i32, i32]:
    Err(9)

fn load_ok -> Result[i32, ContextError[i32]]:
    let x = read_ok().context("read ok")?
    Ok(x + 1)

fn load_err -> Result[i32, ContextError[i32]]:
    let x = read_err().context("read failed")?
    Ok(x)

fn main -> i32:
    assert(load_ok().unwrap_or(0) == 8)
    assert(load_err().is_err())

    let direct: Result[i32, i32] = Err(2)
    let with_msg = direct.context("boom")
    assert(with_msg.is_err())
EOF1
expect_run_pass "$tmpdir/result_context_ok.w"

cat >"$tmpdir/result_with_context_lazy_ok.w" <<'EOF2'
fn make_msg -> str:
    println("ctx-built")
    "ctx"

fn main -> i32:
    let okv: Result[i32, i32] = Ok(1)
    let _a = okv.with_context(make_msg)

    let errv: Result[i32, i32] = Err(2)
    let _b = errv.with_context(make_msg)
EOF2
expect_run_stdout "$tmpdir/result_with_context_lazy_ok.w" "ctx-built"

cat >"$tmpdir/context_on_option_fail.w" <<'EOF3'
fn main -> i32:
    let x: ?i32 = Some(1)
    let _y = x.context("bad")
EOF3
expect_run_fail "$tmpdir/context_on_option_fail.w"

cat >"$tmpdir/context_bad_message_type_fail.w" <<'EOF4'
fn main -> i32:
    let x: Result[i32, i32] = Err(1)
    let _y = x.context(42)
EOF4
expect_run_fail "$tmpdir/context_bad_message_type_fail.w"

cat >"$tmpdir/with_context_bad_arg_fail.w" <<'EOF5'
fn main -> i32:
    let x: Result[i32, i32] = Err(1)
    let _y = x.with_context("oops")
EOF5
expect_run_fail "$tmpdir/with_context_bad_arg_fail.w"

cat >"$tmpdir/with_context_bad_return_type_fail.w" <<'EOF6'
fn build -> i32:
    1

fn main -> i32:
    let x: Result[i32, i32] = Err(1)
    let _y = x.with_context(build)
EOF6
expect_run_fail "$tmpdir/with_context_bad_return_type_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase3 ContextError/context tests: $failures failure(s)"
  exit 1
fi

echo "phase3 ContextError/context tests: PASS"
