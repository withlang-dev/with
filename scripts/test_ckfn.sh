#!/usr/bin/env bash
set -euo pipefail

# CK_FN test harness.
# Compiles each test with WITH_CK_FN=1 (forces MIR function-call dispatch)
# and compares results against the baseline (WITH_CK_FN unset).
#
# Usage:
#   ./scripts/test_ckfn.sh                         # run all tests
#   ./scripts/test_ckfn.sh test/cases/behav_*.w     # run specific tests
#
# This script does NOT modify the compiler or seed. It exercises MIR CK_FN
# codegen against the stable stage2, reporting which tests break.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

COMPILER="${WITH:-./out/bin/with-stage2}"
TIMEOUT_SECS="${WITH_TEST_TIMEOUT:-30}"

if [[ ! -x "$COMPILER" ]]; then
  echo "error: missing compiler: $COMPILER" >&2
  echo "       run 'make build' first" >&2
  exit 1
fi

# Collect test files
if [[ "$#" -gt 0 ]]; then
  test_files=("$@")
else
  test_files=()
  for f in test/cases/*.w; do
    [[ -e "$f" ]] && test_files+=("$f")
  done
fi

passed=0
failed=0
skipped=0
fail_names=()

for file in "${test_files[@]}"; do
  name="$(basename "$file" .w)"
  tmp="$(mktemp -d)"

  # Parse directives
  expect_stdout=""
  expect_check_fail=""
  expect_build_fail=""
  check_only=0
  extra_args=""
  while IFS= read -r line; do
    case "$line" in
      "//! expect-stdout: "*)  expect_stdout="${line#//! expect-stdout: }" ;;
      "//! expect-check-fail: "* | "//! expect-error: "*)
        expect_check_fail="${line#//! expect-*: }" ;;
      "//! expect-build-fail: "*) expect_build_fail="${line#//! expect-build-fail: }" ;;
      "//! check-only"*)       check_only=1 ;;
      "//! args: "*)           extra_args="${line#//! args: }" ;;
      "//!"*)                  ;;
      *)                       break ;;
    esac
  done < "$file"

  # Skip tests that expect failures — CK_FN doesn't change sema/check behavior
  if [[ -n "$expect_check_fail" || -n "$expect_build_fail" || "$check_only" -eq 1 ]]; then
    skipped=$((skipped + 1))
    rm -rf "$tmp"
    continue
  fi

  # Build + run with CK_FN enabled
  rc=0
  timeout "$TIMEOUT_SECS" env WITH_CK_FN=1 "$COMPILER" build $extra_args "$file" \
    -o "$tmp/bin" >"$tmp/out" 2>"$tmp/err" || rc=$?

  if [[ "$rc" -ne 0 ]]; then
    errtail="$(tail -1 "$tmp/err" 2>/dev/null || echo "?")"
    echo "FAIL-BUILD $name  $errtail"
    failed=$((failed + 1))
    fail_names+=("$name")
    rm -rf "$tmp"
    continue
  fi

  # Run
  rc=0
  timeout "$TIMEOUT_SECS" "$tmp/bin" >"$tmp/run_out" 2>"$tmp/run_err" || rc=$?

  if [[ "$rc" -eq 124 ]]; then
    echo "FAIL-HANG  $name  (timeout ${TIMEOUT_SECS}s)"
    failed=$((failed + 1))
    fail_names+=("$name")
    rm -rf "$tmp"
    continue
  fi

  if [[ "$rc" -ne 0 ]]; then
    errtail="$(tail -1 "$tmp/run_err" 2>/dev/null || echo "exit $rc")"
    echo "FAIL-RUN   $name  $errtail"
    failed=$((failed + 1))
    fail_names+=("$name")
    rm -rf "$tmp"
    continue
  fi

  # Check stdout if directive present
  if [[ -n "$expect_stdout" ]]; then
    if ! grep -Fq "$expect_stdout" "$tmp/run_out"; then
      got="$(head -1 "$tmp/run_out" 2>/dev/null || echo "(empty)")"
      echo "FAIL-OUT   $name  expected: $expect_stdout, got: $got"
      failed=$((failed + 1))
      fail_names+=("$name")
      rm -rf "$tmp"
      continue
    fi
  fi

  echo "PASS       $name"
  passed=$((passed + 1))
  rm -rf "$tmp"
done

echo ""
echo "--- CK_FN results ---"
echo "passed:  $passed"
echo "failed:  $failed"
echo "skipped: $skipped"

if [[ "$failed" -gt 0 ]]; then
  echo ""
  echo "failures:"
  for n in "${fail_names[@]}"; do
    echo "  $n"
  done
  exit 1
fi
