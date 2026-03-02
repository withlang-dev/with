#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SELFHOST_BIN="./with-stage2"

echo "rebuilding self-host compiler for Wave 5 unit tests..."
./scripts/rebuild_selfhost.sh stage2 >/dev/null

if [[ ! -x "$SELFHOST_BIN" ]]; then
  echo "error: missing self-host compiler: $SELFHOST_BIN"
  exit 1
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

run_expect_pass_typed() {
  local name="$1"
  local src="$2"
  local expect_pat="$3"
  local out="$tmpdir/${name}.out"
  local err="$tmpdir/${name}.err"

  if ! "$SELFHOST_BIN" check "$src" --dump-typed >"$out" 2>"$err"; then
    echo "FAIL(wave5-unit-pass-check) $src"
    cat "$err"
    failures=$((failures + 1))
    return
  fi

  if ! grep -q "$expect_pat" "$out"; then
    echo "FAIL(wave5-unit-pass-pattern) $src pattern=$expect_pat"
    cat "$out"
    failures=$((failures + 1))
    return
  fi

  echo "PASS(wave5-unit-pass) $src"
}

run_expect_fail() {
  local name="$1"
  local src="$2"
  local expect_err_pat="$3"
  local out="$tmpdir/${name}.out"
  local err="$tmpdir/${name}.err"

  if "$SELFHOST_BIN" check "$src" >"$out" 2>"$err"; then
    echo "FAIL(wave5-unit-fail-expected-error) $src"
    cat "$out"
    failures=$((failures + 1))
    return
  fi

  if ! grep -q "$expect_err_pat" "$err"; then
    echo "FAIL(wave5-unit-fail-pattern) $src pattern=$expect_err_pat"
    cat "$err"
    failures=$((failures + 1))
    return
  fi

  echo "PASS(wave5-unit-fail) $src"
}

run_expect_pass_typed "generic_return" "test/wave5/cases/generic_return_infer.w" "bind a: i32"
run_expect_pass_typed "generic_bound_pass" "test/wave5/cases/generic_bound_pass.w" "impl Show for Foo"
run_expect_fail "duplicate_impl" "test/wave5/cases/duplicate_impl_error.w" "duplicate implementation of trait for type"
run_expect_fail "unknown_trait" "test/wave5/cases/unknown_trait_error.w" "unknown trait"
run_expect_fail "generic_bound_error" "test/wave5/cases/generic_bound_error.w" "does not implement trait 'Show' required by bound 'T: Show'"
run_expect_fail "dyn_trait_param_error" "test/wave5/cases/dyn_trait_param_error.w" "does not implement trait 'Describable' required for dyn parameter"

if [[ "$failures" -ne 0 ]]; then
  echo "wave5 type+trait unit tests: $failures failure(s)"
  exit 1
fi

echo "wave5 type+trait unit tests: PASS"
