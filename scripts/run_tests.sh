#!/usr/bin/env bash
set -euo pipefail

# Unified selfhost test runner.
# Runs all test cases in test/cases/ using the stage2 compiler.
#
# Usage:
#   ./scripts/run_tests.sh              # run all tests
#   ./scripts/run_tests.sh test/cases/behav_*.w  # run specific tests
#
# Test files use header directives:
#   //! expect-stdout: <text>   — build+run, check stdout contains <text>
#   //! expect-check-fail: <msg> — check mode should fail with <msg>
#   //! expect-build-fail: <msg> — build mode should fail with <msg>
#   //! check-only               — only run check mode (no build/run)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
source "${ROOT_DIR}/scripts/selfhost_runner.sh"

COMPILER="${WITH:-./out/bin/with-stage2}"
RUN_TIMEOUT_SECS="${WITH_TEST_TIMEOUT:-30}"

if [[ ! -x "$COMPILER" ]]; then
  echo "error: missing compiler: $COMPILER" >&2
  echo "       run 'make build' first" >&2
  exit 1
fi

COMPILER="$(prepare_selfhost_runner "$ROOT_DIR" "$COMPILER")"
trap 'cleanup_selfhost_runner' EXIT

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"; cleanup_selfhost_runner' EXIT

passed=0
failed=0
skipped=0
failures_list=""

run_test() {
  local file="$1"
  local expect_stdout=""
  local expect_check_fail=""
  local expect_build_fail=""
  local check_only=0

  # Parse directives from file header
  while IFS= read -r line; do
    case "$line" in
      "//! expect-stdout: "*)
        expect_stdout="${line#//! expect-stdout: }"
        ;;
      "//! expect-check-fail: "*)
        expect_check_fail="${line#//! expect-check-fail: }"
        ;;
      "//! expect-build-fail: "*)
        expect_build_fail="${line#//! expect-build-fail: }"
        ;;
      "//! check-only"*)
        check_only=1
        ;;
      "//!"*)
        ;;
      *)
        break
        ;;
    esac
  done < "$file"

  local name
  name="$(basename "$file" .w)"

  # Case 1: expect check to fail with message
  if [[ -n "$expect_check_fail" ]]; then
    local rc=0
    runner_exec_capture "$RUN_TIMEOUT_SECS" "$tmpdir/out" "$tmpdir/err" "$COMPILER" check "$file" || rc=$?
    if [[ "$rc" -eq 0 ]]; then
      echo "FAIL $name (expected check failure)"
      failed=$((failed + 1))
      failures_list="${failures_list}  ${file}\n"
      return
    fi
    if grep -Fq "$expect_check_fail" "$tmpdir/err"; then
      echo "PASS $name"
      passed=$((passed + 1))
    else
      echo "FAIL $name (missing error: $expect_check_fail)"
      failed=$((failed + 1))
      failures_list="${failures_list}  ${file}\n"
    fi
    return
  fi

  # Case 2: expect build to fail with message
  if [[ -n "$expect_build_fail" ]]; then
    local rc=0
    runner_exec_capture "$RUN_TIMEOUT_SECS" "$tmpdir/out" "$tmpdir/err" "$COMPILER" build "$file" || rc=$?
    if [[ "$rc" -eq 0 ]]; then
      echo "FAIL $name (expected build failure)"
      failed=$((failed + 1))
      failures_list="${failures_list}  ${file}\n"
    elif grep -Fq "$expect_build_fail" "$tmpdir/err"; then
      echo "PASS $name"
      passed=$((passed + 1))
    else
      echo "FAIL $name (missing error: $expect_build_fail)"
      failed=$((failed + 1))
      failures_list="${failures_list}  ${file}\n"
    fi
    # Clean up any artifacts
    local stem="${file%.w}"
    rm -f "$stem" "${stem}.o" 2>/dev/null || true
    return
  fi

  # Case 3: check-only (no build/run)
  if [[ "$check_only" -eq 1 ]]; then
    local rc=0
    runner_exec_capture "$RUN_TIMEOUT_SECS" "$tmpdir/out" "$tmpdir/err" "$COMPILER" check "$file" || rc=$?
    if [[ "$rc" -eq 0 ]]; then
      echo "PASS $name"
      passed=$((passed + 1))
    else
      echo "FAIL $name (check failed)"
      tail -5 "$tmpdir/err" 2>/dev/null || true
      failed=$((failed + 1))
      failures_list="${failures_list}  ${file}\n"
    fi
    return
  fi

  # Case 4: build+run, check stdout
  if [[ -z "$expect_stdout" ]]; then
    # No directive — default to expecting "ok"
    expect_stdout="ok"
  fi

  local rc=0
  runner_exec_capture "$RUN_TIMEOUT_SECS" "$tmpdir/out" "$tmpdir/err" "$COMPILER" run "$file" || rc=$?

  # Clean up artifacts
  local stem="${file%.w}"
  rm -f "$stem" "${stem}.o" 2>/dev/null || true

  if [[ "$rc" -eq 124 ]]; then
    echo "FAIL $name (timeout after ${RUN_TIMEOUT_SECS}s)"
    failed=$((failed + 1))
    failures_list="${failures_list}  ${file}\n"
    return
  fi

  if [[ "$rc" -ne 0 ]]; then
    echo "FAIL $name (exit code $rc)"
    tail -5 "$tmpdir/err" 2>/dev/null || true
    failed=$((failed + 1))
    failures_list="${failures_list}  ${file}\n"
    return
  fi

  if grep -Fq "$expect_stdout" "$tmpdir/out"; then
    echo "PASS $name"
    passed=$((passed + 1))
  else
    echo "FAIL $name (stdout mismatch, expected: $expect_stdout)"
    echo "  got: $(head -1 "$tmpdir/out" 2>/dev/null || echo "(empty)")"
    failed=$((failed + 1))
    failures_list="${failures_list}  ${file}\n"
  fi
}

# Collect test files
if [[ "$#" -gt 0 ]]; then
  test_files=("$@")
else
  test_files=()
  for f in test/cases/*.w; do
    [[ -e "$f" ]] && test_files+=("$f")
  done
fi

echo "=== selfhost test suite ==="
echo "compiler: $COMPILER"
echo "tests: ${#test_files[@]}"
echo ""

for f in "${test_files[@]}"; do
  run_test "$f"
done

echo ""
echo "--- results ---"
echo "passed: $passed"
echo "failed: $failed"
if [[ -n "$failures_list" ]]; then
  echo ""
  echo "failures:"
  printf "$failures_list"
fi

if [[ "$failed" -gt 0 ]]; then
  exit 1
fi
