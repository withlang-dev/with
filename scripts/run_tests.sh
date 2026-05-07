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
#   //! expect-stdout: <text>   — test mode should run and see stdout containing <text>
#   //! expect-check-fail: <msg> — check mode should fail with <msg>
#   //! expect-build-fail: <msg> — build mode should fail with <msg>
#   //! check-only               — only run check mode (no build/run)
#   //! skip: <reason>           — skip with an explicit justification
#
# Environment:
#   WITH_TEST_JOBS=N     — number of parallel jobs (default: CPU count)
#   WITH_TEST_TIMING=1   — show per-test timing, under-load summaries, suite throughput, and isolated reruns
#   WITH_TEST_TIMING_ISOLATED_TOP=N — with timing enabled, rerun top N slow under-load tests serially (default: 10, 0 disables)
#   WITH_TEST_TIMING_PHASES_TOP=N — with timing enabled, profile top N isolated reruns and print compiler phase breakdowns (default: 5, 0 disables)
#   WITH_TEST_TIMEOUT=N  — per-test timeout in seconds (default: 30)
#   WITH_TEST_DEBUG=1    — keep debug info for ephemeral test binaries (default: 0, pass -g0)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
source "${ROOT_DIR}/scripts/selfhost_runner.sh"

COMPILER="${WITH:-./out/bin/with-stage2}"
RUN_TIMEOUT_SECS="${WITH_TEST_TIMEOUT:-30}"
JOBS="${WITH_TEST_JOBS:-$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)}"
SHOW_TIMING="${WITH_TEST_TIMING:-0}"
ISOLATED_TIMING_TOP="${WITH_TEST_TIMING_ISOLATED_TOP:-10}"
PHASE_TIMING_TOP="${WITH_TEST_TIMING_PHASES_TOP:-5}"
KEEP_TEST_DEBUG="${WITH_TEST_DEBUG:-0}"

# Portable millisecond clock. Uses perl for sub-second precision
# (bash SECONDS is integer-only, and date %N is not available on macOS).
_epoch_ms() {
  perl -MTime::HiRes=time -e 'printf "%d\n", time()*1000'
}

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
  for dir in test/behavior test/compile_errors test/codegen test/spec; do
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

parse_test_directives() {
  local file="$1"
  TEST_EXPECT_STDOUT=""
  TEST_EXPECT_CHECK_FAIL=""
  TEST_EXPECT_BUILD_FAIL=""
  TEST_EXPECT_CHECK_STDOUT=""
  TEST_EXPECT_EXIT=""
  TEST_EXPECT_STDERR=""
  TEST_CHECK_ONLY=0
  TEST_EXTRA_ARGS=""
  TEST_SKIP=0
  TEST_SKIP_REASON=""

  while IFS= read -r line; do
    case "$line" in
      "//! skip: "*)
        TEST_SKIP=1
        TEST_SKIP_REASON="${line#//! skip: }"
        return
        ;;
      "//! skip"*)
        TEST_SKIP=1
        TEST_SKIP_REASON=""
        return
        ;;
      "//! expect-stdout: "*)
        TEST_EXPECT_STDOUT="${line#//! expect-stdout: }"
        ;;
      "//! expect-check-fail: "*)
        TEST_EXPECT_CHECK_FAIL="${line#//! expect-check-fail: }"
        ;;
      "//! expect-error: "*)
        TEST_EXPECT_CHECK_FAIL="${line#//! expect-error: }"
        ;;
      "//! expect-build-fail: "*)
        TEST_EXPECT_BUILD_FAIL="${line#//! expect-build-fail: }"
        ;;
      "//! check-only"*)
        TEST_CHECK_ONLY=1
        ;;
      "//! expect-check-stdout: "*)
        TEST_EXPECT_CHECK_STDOUT="${line#//! expect-check-stdout: }"
        ;;
      "//! args: "*)
        TEST_EXTRA_ARGS="${line#//! args: }"
        ;;
      "//! expect-exit: "*)
        TEST_EXPECT_EXIT="${line#//! expect-exit: }"
        ;;
      "//! expect-stderr: "*)
        TEST_EXPECT_STDERR="${line#//! expect-stderr: }"
        ;;
      "//!"*)
        ;;
      *)
        break
        ;;
    esac
  done < "$file"
}

profile_test_phases() {
  local file="$1"
  local debug_args=""
  if [[ "$KEEP_TEST_DEBUG" != "1" ]]; then
    debug_args="-g0"
  fi

  parse_test_directives "$file"
  if [[ "$TEST_SKIP" -eq 1 ]]; then
    return
  fi

  local my_tmp
  my_tmp="$(mktemp -d)"
  local rc=0

  if [[ -n "$TEST_EXPECT_CHECK_FAIL" ]]; then
    WITH_PROFILE=1 timeout "$RUN_TIMEOUT_SECS" "$COMPILER" check $TEST_EXTRA_ARGS "$file" >"$my_tmp/out" 2>"$my_tmp/err" || rc=$?
  elif [[ -n "$TEST_EXPECT_BUILD_FAIL" ]]; then
    WITH_PROFILE=1 timeout "$RUN_TIMEOUT_SECS" "$COMPILER" build $debug_args $TEST_EXTRA_ARGS "$file" >"$my_tmp/out" 2>"$my_tmp/err" || rc=$?
    local stem="${file%.w}"
    rm -f "$stem" "${stem}.o" 2>/dev/null || true
  elif [[ -n "$TEST_EXPECT_CHECK_STDOUT" || "$TEST_CHECK_ONLY" -eq 1 ]]; then
    WITH_PROFILE=1 timeout "$RUN_TIMEOUT_SECS" "$COMPILER" check $TEST_EXTRA_ARGS "$file" >"$my_tmp/out" 2>"$my_tmp/err" || rc=$?
  else
    WITH_PROFILE=1 timeout "$RUN_TIMEOUT_SECS" "$COMPILER" test $debug_args $TEST_EXTRA_ARGS "$file" >"$my_tmp/out" 2>"$my_tmp/err" || rc=$?
  fi

  if [[ -z "$TEST_EXPECT_CHECK_FAIL" && -z "$TEST_EXPECT_BUILD_FAIL" && "$rc" -ne 0 ]]; then
    rm -rf "$my_tmp"
    return 1
  fi

  grep '^\[profile\]' "$my_tmp/err" | awk '
    {
      phase = $2
      ms = $3 + 0
      printf "%s\t%.3f\n", phase, ms
    }
  '

  rm -rf "$my_tmp"
}

run_single_test() {
  local file="$1"
  local result_file="$2"
  local name
  name="$(basename "$file" .w)"
  local debug_args=""
  if [[ "$KEEP_TEST_DEBUG" != "1" ]]; then
    debug_args="-g0"
  fi

  local t_start
  t_start="$(_epoch_ms)"

  # Write result with elapsed time appended as a tab-separated field.
  # Format: "PASS name\t<ms>" or "FAIL name (reason)\t<ms>"
  _emit_result() {
    local msg="$1"
    local t_end
    t_end="$(_epoch_ms)"
    local elapsed_ms=$(( t_end - t_start ))
    printf '%s\t%d\t%s\n' "$msg" "$elapsed_ms" "$file" > "$result_file"
  }

  local my_tmp
  my_tmp="$(mktemp -d)"

  parse_test_directives "$file"

  # Case 1: expect check to fail with message
  if [[ "$TEST_SKIP" -eq 1 ]]; then
    if [[ -z "$TEST_SKIP_REASON" ]]; then
      _emit_result "FAIL $name (skip missing reason)"
    else
      _emit_result "SKIP $name ($TEST_SKIP_REASON)"
    fi
    rm -rf "$my_tmp"
    return
  fi
  if [[ -n "$TEST_EXPECT_CHECK_FAIL" ]]; then
    local rc=0
    timeout "$RUN_TIMEOUT_SECS" "$COMPILER" check $TEST_EXTRA_ARGS "$file" >"$my_tmp/out" 2>"$my_tmp/err" || rc=$?
    if [[ "$rc" -eq 0 ]]; then
      _emit_result "FAIL $name (expected check failure)"
      rm -rf "$my_tmp"
      return
    fi
    if grep -Fq "$TEST_EXPECT_CHECK_FAIL" "$my_tmp/err"; then
      _emit_result "PASS $name"
    else
      _emit_result "FAIL $name (missing error: $TEST_EXPECT_CHECK_FAIL)"
    fi
    rm -rf "$my_tmp"
    return
  fi

  # Case 2: expect build to fail with message
  if [[ -n "$TEST_EXPECT_BUILD_FAIL" ]]; then
    local rc=0
    timeout "$RUN_TIMEOUT_SECS" "$COMPILER" build $debug_args $TEST_EXTRA_ARGS "$file" >"$my_tmp/out" 2>"$my_tmp/err" || rc=$?
    if [[ "$rc" -eq 0 ]]; then
      _emit_result "FAIL $name (expected build failure)"
    elif grep -Fq "$TEST_EXPECT_BUILD_FAIL" "$my_tmp/err"; then
      _emit_result "PASS $name"
    else
      _emit_result "FAIL $name (missing error: $TEST_EXPECT_BUILD_FAIL)"
    fi
    local stem="${file%.w}"
    rm -f "$stem" "${stem}.o" 2>/dev/null || true
    rm -rf "$my_tmp"
    return
  fi

  # Case 2b: check with expected stdout (for dump tests)
  if [[ -n "$TEST_EXPECT_CHECK_STDOUT" ]]; then
    local rc=0
    timeout "$RUN_TIMEOUT_SECS" "$COMPILER" check $TEST_EXTRA_ARGS "$file" >"$my_tmp/out" 2>"$my_tmp/err" || rc=$?
    if [[ "$rc" -ne 0 ]]; then
      _emit_result "FAIL $name (check failed with rc=$rc)"
    elif grep -Fq "$TEST_EXPECT_CHECK_STDOUT" "$my_tmp/out"; then
      _emit_result "PASS $name"
    else
      local got
      got="$(head -5 "$my_tmp/out")"
      _emit_result "FAIL $name (missing output: $TEST_EXPECT_CHECK_STDOUT, got: $got)"
    fi
    rm -rf "$my_tmp"
    return
  fi

  # Case 3: check-only (no build/run)
  if [[ "$TEST_CHECK_ONLY" -eq 1 ]]; then
    local rc=0
    timeout "$RUN_TIMEOUT_SECS" "$COMPILER" check $TEST_EXTRA_ARGS "$file" >"$my_tmp/out" 2>"$my_tmp/err" || rc=$?
    if [[ "$rc" -eq 0 ]]; then
      _emit_result "PASS $name"
    else
      _emit_result "FAIL $name (check failed)"
    fi
    rm -rf "$my_tmp"
    return
  fi

  # Case 4: positive tests. `with test` owns executable directives
  # (expect-stdout, expect-stderr, expect-exit) and also supports
  # attribute-only tests with no fn main.
  local rc=0
  timeout "$RUN_TIMEOUT_SECS" "$COMPILER" test $debug_args $TEST_EXTRA_ARGS "$file" >"$my_tmp/out" 2>"$my_tmp/err" || rc=$?

  if [[ "$rc" -eq 124 ]]; then
    _emit_result "FAIL $name (timeout after ${RUN_TIMEOUT_SECS}s)"
    rm -rf "$my_tmp"
    return
  fi

  if [[ "$rc" -ne 0 ]]; then
    local errtail
    errtail="$(tail -3 "$my_tmp/err" 2>/dev/null || true)"
    _emit_result "FAIL $name (exit code $rc) $errtail"
    rm -rf "$my_tmp"
    return
  fi

  _emit_result "PASS $name"
  rm -rf "$my_tmp"
}

export -f parse_test_directives profile_test_phases run_single_test _epoch_ms
export results_dir

suite_start_ms="$(_epoch_ms)"

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

suite_end_ms="$(_epoch_ms)"
suite_elapsed_ms=$(( suite_end_ms - suite_start_ms ))

# Collect results
passed=0
failed=0
skipped=0
failures_list=""
timing_data=""

for result_file in "$results_dir"/result_*; do
  [[ -e "$result_file" ]] || continue
  raw="$(cat "$result_file")"
  # Split on tab: message \t elapsed_ms \t file
  msg="${raw%%	*}"
  rest="${raw#*	}"
  ms="${rest%%	*}"
  file="${rest#*	}"
  # If no tab (shouldn't happen), treat whole line as message, ms=0, file=""
  if [[ "$msg" == "$raw" ]]; then
    ms=0
    file=""
  fi

  if [[ "$SHOW_TIMING" == "1" ]]; then
    printf "%s  (%d ms)\n" "$msg" "$ms"
  else
    echo "$msg"
  fi

  timing_data="${timing_data}${ms}	${msg}	${file}\n"

  case "$msg" in
    PASS*)
      passed=$((passed + 1))
      ;;
    SKIP*)
      skipped=$((skipped + 1))
      ;;
    FAIL*)
      failed=$((failed + 1))
      failures_list="${failures_list}  ${msg}\n"
      ;;
  esac
done

echo ""
echo "--- results ---"
echo "passed: $passed"
echo "skipped: $skipped"
echo "failed: $failed"
if [[ -n "$failures_list" ]]; then
  echo ""
  echo "failures:"
  printf "$failures_list"
fi

if [[ "$SHOW_TIMING" == "1" ]]; then
  suite_elapsed_secs="$(awk -v ms="$suite_elapsed_ms" 'BEGIN { printf "%.3f", ms / 1000.0 }')"
  tests_per_sec="$(awk -v count="$passed" -v skipped="$skipped" -v failed="$failed" -v ms="$suite_elapsed_ms" 'BEGIN { if (ms <= 0) { print "0.00"; } else { printf "%.2f", (count + skipped + failed) * 1000.0 / ms } }')"

  echo ""
  echo "--- suite throughput ---"
  printf "  %6d ms  full suite wall time under load\n" "$suite_elapsed_ms"
  printf "  %6s s   elapsed seconds\n" "$suite_elapsed_secs"
  printf "  %6s     tests/sec with jobs=%s\n" "$tests_per_sec" "$JOBS"

  echo ""
  echo "--- slowest tests under load ---"
  printf "%b" "$timing_data" | sort -t'	' -k1 -rn | head -20 | while IFS='	' read -r tms tname tfile; do
    [[ -z "$tms" ]] && continue
    printf "  %6d ms  %s\n" "$tms" "$tname"
  done

  print_threshold_summary() {
    local threshold_ms="$1"
    local label="$2"
    local count
    count="$(
      printf "%b" "$timing_data" |
        awk -F'	' -v min_ms="$threshold_ms" 'NF >= 2 && ($1 + 0) > min_ms { c += 1 } END { print c + 0 }'
    )"

    echo ""
    echo "--- tests over ${label} under load (${count}) ---"
    if [[ "$count" -eq 0 ]]; then
      return
    fi

    printf "%b" "$timing_data" |
      awk -F'	' -v min_ms="$threshold_ms" 'NF >= 2 && ($1 + 0) > min_ms { print }' |
      sort -t'	' -k1 -rn |
      head -20 |
      while IFS='	' read -r tms tname tfile; do
        [[ -z "$tms" ]] && continue
        printf "  %6d ms  %s\n" "$tms" "$tname"
      done
  }

  print_threshold_summary 5000 "5s"
  print_threshold_summary 10000 "10s"

  if [[ "$failed" -eq 0 && "$ISOLATED_TIMING_TOP" -gt 0 ]]; then
    isolated_tmp="$(mktemp -d)"
    top_under_load_file="$isolated_tmp/top_under_load.tsv"

    printf "%b" "$timing_data" |
      awk -F'	' 'NF >= 3 && $3 != "" { print }' |
      sort -t'	' -k1 -rn |
      head -"$ISOLATED_TIMING_TOP" > "$top_under_load_file"

    echo ""
    echo "--- isolated rerun of top ${ISOLATED_TIMING_TOP} under-load tests ---"

    while IFS='	' read -r under_ms under_msg under_file; do
      [[ -z "$under_file" ]] && continue
      isolated_result="$isolated_tmp/result.tsv"
      run_single_test "$under_file" "$isolated_result"
      isolated_raw="$(cat "$isolated_result")"
      isolated_msg="${isolated_raw%%	*}"
      isolated_rest="${isolated_raw#*	}"
      isolated_ms="${isolated_rest%%	*}"
      delta_ms=$(( under_ms - isolated_ms ))

      if [[ "$isolated_msg" != PASS* ]]; then
        printf "  %6d ms isolated / %6d ms under load  %s  (isolated rerun: %s)\n" "$isolated_ms" "$under_ms" "$isolated_msg" "$isolated_msg"
      else
        printf "  %6d ms isolated / %6d ms under load  %s  (contention %+d ms)\n" "$isolated_ms" "$under_ms" "$isolated_msg" "$delta_ms"
      fi
    done < "$top_under_load_file"

    rm -rf "$isolated_tmp"
  fi

  if [[ "$failed" -eq 0 && "$PHASE_TIMING_TOP" -gt 0 ]]; then
    phase_tmp="$(mktemp -d)"
    top_phase_file="$phase_tmp/top_phase.tsv"

    printf "%b" "$timing_data" |
      awk -F'	' 'NF >= 3 && $3 != "" { print }' |
      sort -t'	' -k1 -rn |
      head -"$PHASE_TIMING_TOP" > "$top_phase_file"

    echo ""
    echo "--- compiler phase breakdown for top ${PHASE_TIMING_TOP} under-load tests ---"
    echo "  phase totals come from WITH_PROFILE; residual = isolated wall minus summed compiler phases"

    while IFS='	' read -r under_ms under_msg under_file; do
      [[ -z "$under_file" ]] && continue
      isolated_result="$phase_tmp/result.tsv"
      run_single_test "$under_file" "$isolated_result"
      isolated_raw="$(cat "$isolated_result")"
      isolated_msg="${isolated_raw%%	*}"
      isolated_rest="${isolated_raw#*	}"
      isolated_ms="${isolated_rest%%	*}"

      if [[ "$isolated_msg" != PASS* ]]; then
        printf "  %s\n" "$isolated_msg"
        continue
      fi

      phase_data="$(profile_test_phases "$under_file" || true)"
      profile_sum="$(printf "%s\n" "$phase_data" | awk -F'	' 'NF >= 2 { sum += $2 } END { printf "%.3f", sum + 0.0 }')"
      residual_ms="$(awk -v total="$isolated_ms" -v prof="$profile_sum" 'BEGIN { printf "%.3f", total - prof }')"

      printf "  %s\n" "$isolated_msg"
      printf "      isolated wall: %s ms\n" "$isolated_ms"
      printf "      compiler sum: %s ms\n" "$profile_sum"
      printf "      residual:     %s ms\n" "$residual_ms"

      if [[ -n "$phase_data" ]]; then
        printf "%s\n" "$phase_data" |
          sort -t'	' -k2,2nr |
          head -5 |
          while IFS='	' read -r phase_name phase_ms; do
            [[ -z "$phase_name" ]] && continue
            printf "      %16s  %8s ms\n" "$phase_name" "$phase_ms"
          done
      fi
    done < "$top_phase_file"

    rm -rf "$phase_tmp"
  fi
fi

if [[ "$failed" -gt 0 ]]; then
  exit 1
fi
