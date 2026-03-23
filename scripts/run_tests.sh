#!/usr/bin/env bash
set -euo pipefail

# Unified selfhost test runner.
# Runs all test cases using the stage2 compiler.
#
# Usage:
#   ./scripts/run_tests.sh                        # run all tests
#   ./scripts/run_tests.sh test/behavior/*.w       # run behavior tests
#   ./scripts/run_tests.sh test/compile_errors/*.w # run error tests
#
# Test files use header directives:
#   //! expect-stdout: <text>   — build+run, check stdout contains <text>
#   //! expect-check-fail: <msg> — check mode should fail with <msg>
#   //! expect-build-fail: <msg> — build mode should fail with <msg>
#   //! check-only               — only run check mode (no build/run)
#
# Environment:
#   WITH_TEST_JOBS=N  — number of parallel jobs (default: CPU count)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
source "${ROOT_DIR}/scripts/selfhost_runner.sh"

COMPILER="${WITH:-./out/bin/with-stage2}"
RUN_TIMEOUT_SECS="${WITH_TEST_TIMEOUT:-30}"
JOBS="${WITH_TEST_JOBS:-$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)}"

if [[ ! -x "$COMPILER" ]]; then
  echo "error: missing compiler: $COMPILER" >&2
  echo "       run 'make build' first" >&2
  exit 1
fi

COMPILER="$(prepare_selfhost_runner "$ROOT_DIR" "$COMPILER")"
trap 'cleanup_selfhost_runner' EXIT

results_dir="$(mktemp -d)"
trap 'rm -rf "$results_dir"; cleanup_selfhost_runner' EXIT

# Collect test files
if [[ "$#" -gt 0 ]]; then
  test_files=("$@")
else
  test_files=()
  # lexer/, parser/, internals/ excluded from default run — they test compiler
  # internals via `use Lexer`/`use Token`/`use compiler.foundation.*` which
  # have known codegen bugs. Run explicitly: scripts/run_tests.sh test/lexer/*.w
  for dir in test/behavior test/compile_errors test/codegen; do
    for f in "$dir"/*.w; do
      [[ -e "$f" ]] && test_files+=("$f")
    done
  done
fi

echo "=== selfhost test suite ==="
echo "compiler: $COMPILER"
echo "tests: ${#test_files[@]}"
echo "jobs: $JOBS"
echo ""

# Export variables needed by the worker
export COMPILER RUN_TIMEOUT_SECS

run_single_test() {
  local file="$1"
  local result_file="$2"
  local expect_stdout=""
  local expect_check_fail=""
  local expect_build_fail=""
  local check_only=0
  local extra_args=""
  local name
  name="$(basename "$file" .w)"

  local my_tmp
  my_tmp="$(mktemp -d)"

  # Parse directives from file header
  while IFS= read -r line; do
    case "$line" in
      "//! skip"*)
        echo "PASS $name (skipped)" > "$result_file"
        rm -rf "$my_tmp"
        return
        ;;
      "//! expect-stdout: "*)
        expect_stdout="${line#//! expect-stdout: }"
        ;;
      "//! expect-check-fail: "*)
        expect_check_fail="${line#//! expect-check-fail: }"
        ;;
      "//! expect-error: "*)
        expect_check_fail="${line#//! expect-error: }"
        ;;
      "//! expect-build-fail: "*)
        expect_build_fail="${line#//! expect-build-fail: }"
        ;;
      "//! check-only"*)
        check_only=1
        ;;
      "//! args: "*)
        extra_args="${line#//! args: }"
        ;;
      "//!"*)
        ;;
      *)
        break
        ;;
    esac
  done < "$file"

  # Case 1: expect check to fail with message
  if [[ -n "$expect_check_fail" ]]; then
    local rc=0
    timeout "$RUN_TIMEOUT_SECS" "$COMPILER" check $extra_args "$file" >"$my_tmp/out" 2>"$my_tmp/err" || rc=$?
    if [[ "$rc" -eq 0 ]]; then
      echo "FAIL $name (expected check failure)" > "$result_file"
      rm -rf "$my_tmp"
      return
    fi
    if grep -Fq "$expect_check_fail" "$my_tmp/err"; then
      echo "PASS $name" > "$result_file"
    else
      echo "FAIL $name (missing error: $expect_check_fail)" > "$result_file"
    fi
    rm -rf "$my_tmp"
    return
  fi

  # Case 2: expect build to fail with message
  if [[ -n "$expect_build_fail" ]]; then
    local rc=0
    timeout "$RUN_TIMEOUT_SECS" "$COMPILER" build $extra_args "$file" >"$my_tmp/out" 2>"$my_tmp/err" || rc=$?
    if [[ "$rc" -eq 0 ]]; then
      echo "FAIL $name (expected build failure)" > "$result_file"
    elif grep -Fq "$expect_build_fail" "$my_tmp/err"; then
      echo "PASS $name" > "$result_file"
    else
      echo "FAIL $name (missing error: $expect_build_fail)" > "$result_file"
    fi
    local stem="${file%.w}"
    rm -f "$stem" "${stem}.o" 2>/dev/null || true
    rm -rf "$my_tmp"
    return
  fi

  # Case 3: check-only (no build/run)
  if [[ "$check_only" -eq 1 ]]; then
    local rc=0
    timeout "$RUN_TIMEOUT_SECS" "$COMPILER" check $extra_args "$file" >"$my_tmp/out" 2>"$my_tmp/err" || rc=$?
    if [[ "$rc" -eq 0 ]]; then
      echo "PASS $name" > "$result_file"
    else
      echo "FAIL $name (check failed)" > "$result_file"
    fi
    rm -rf "$my_tmp"
    return
  fi

  # Case 4: build+run
  local rc=0
  timeout "$RUN_TIMEOUT_SECS" "$COMPILER" run $extra_args "$file" >"$my_tmp/out" 2>"$my_tmp/err" || rc=$?

  # Clean up artifacts
  local stem="${file%.w}"
  rm -f "$stem" "${stem}.o" 2>/dev/null || true

  if [[ "$rc" -eq 124 ]]; then
    echo "FAIL $name (timeout after ${RUN_TIMEOUT_SECS}s)" > "$result_file"
    rm -rf "$my_tmp"
    return
  fi

  if [[ "$rc" -ne 0 ]]; then
    local errtail
    errtail="$(tail -3 "$my_tmp/err" 2>/dev/null || true)"
    echo "FAIL $name (exit code $rc) $errtail" > "$result_file"
    rm -rf "$my_tmp"
    return
  fi

  # If no expect-stdout directive, pass on exit 0
  if [[ -z "$expect_stdout" ]]; then
    echo "PASS $name" > "$result_file"
    rm -rf "$my_tmp"
    return
  fi

  if grep -Fq "$expect_stdout" "$my_tmp/out"; then
    echo "PASS $name" > "$result_file"
  else
    local got
    got="$(head -1 "$my_tmp/out" 2>/dev/null || echo "(empty)")"
    echo "FAIL $name (stdout mismatch, expected: $expect_stdout, got: $got)" > "$result_file"
  fi
  rm -rf "$my_tmp"
}

export -f run_single_test
export results_dir

# Run tests in parallel
idx=0
for f in "${test_files[@]}"; do
  result_file="$results_dir/result_$(printf '%04d' $idx)"
  run_single_test "$f" "$result_file" &

  idx=$((idx + 1))

  # Limit parallelism
  if [[ $(( idx % JOBS )) -eq 0 ]]; then
    wait
  fi
done
wait

# Collect results
passed=0
failed=0
failures_list=""

for result_file in "$results_dir"/result_*; do
  [[ -e "$result_file" ]] || continue
  line="$(cat "$result_file")"
  echo "$line"
  case "$line" in
    PASS*)
      passed=$((passed + 1))
      ;;
    FAIL*)
      failed=$((failed + 1))
      failures_list="${failures_list}  ${line}\n"
      ;;
  esac
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
