#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
source "${ROOT_DIR}/scripts/selfhost_runner.sh"

SELFHOST_BIN="${ROOT_DIR}/with-stage2"
CHECK_TIMEOUT_SECS="${PARITY_CHECK_TIMEOUT_SECS:-60}"
RUN_TIMEOUT_SECS="${PARITY_RUN_TIMEOUT_SECS:-25}"
CLI_TIMEOUT_SECS="${PARITY_CLI_TIMEOUT_SECS:-25}"

echo "rebuilding self-host compiler for Wave 11 unit tests..."
./scripts/rebuild_selfhost.sh stage2 >/dev/null

if [[ ! -x "$SELFHOST_BIN" ]]; then
  echo "error: missing self-host compiler: $SELFHOST_BIN"
  exit 1
fi

SELFHOST_BIN="$(prepare_selfhost_runner "$ROOT_DIR" "$SELFHOST_BIN")"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"; cleanup_selfhost_runner' EXIT

cat >"$tmpdir/ext_add.c" <<'C1'
int ext_add(int a, int b) { return a + b + 5; }
C1
cc -c "$tmpdir/ext_add.c" -o "$tmpdir/ext_add.o"
ar rcs "$tmpdir/libextadd.a" "$tmpdir/ext_add.o"
export LIBRARY_PATH="$tmpdir${LIBRARY_PATH:+:$LIBRARY_PATH}"

failures=0

cleanup_artifacts() {
  local src="$1"
  if [[ "$src" != *.w ]]; then
    return
  fi
  local stem="${src%.w}"
  if [[ -f "$stem" ]]; then
    unlink "$stem" || true
  fi
  if [[ -f "${stem}.o" ]]; then
    unlink "${stem}.o" || true
  fi
}

run_mode() {
  local mode="$1"
  local src="$2"
  local out_file="$3"
  local err_file="$4"
  local timeout_secs="$CHECK_TIMEOUT_SECS"

  if [[ "$mode" == "run" ]]; then
    timeout_secs="$RUN_TIMEOUT_SECS"
  fi

  runner_exec_capture "$timeout_secs" "$out_file" "$err_file" "$SELFHOST_BIN" "$mode" "$src"
}

run_with_optional_timeout() {
  local timeout_secs="$1"
  local out_file="$2"
  local err_file="$3"
  shift 3
  runner_exec_capture "$timeout_secs" "$out_file" "$err_file" "$@"
}

run_cli_key() {
  local key="$1"
  local out_file="$2"
  local err_file="$3"

  case "$key" in
    help)
      run_with_optional_timeout "$CLI_TIMEOUT_SECS" "$out_file" "$err_file" "$SELFHOST_BIN" help
      ;;
    version)
      run_with_optional_timeout "$CLI_TIMEOUT_SECS" "$out_file" "$err_file" "$SELFHOST_BIN" version
      ;;
    unknown_command)
      run_with_optional_timeout "$CLI_TIMEOUT_SECS" "$out_file" "$err_file" "$SELFHOST_BIN" does_not_exist
      ;;
    build_missing_arg)
      local build_dir="$tmpdir/build_missing_arg_case"
      mkdir -p "$build_dir"
      (
        cd "$build_dir"
        run_with_optional_timeout "$CLI_TIMEOUT_SECS" "$out_file" "$err_file" "$SELFHOST_BIN" build
      )
      ;;
    run_missing_arg)
      local run_dir="$tmpdir/run_missing_arg_case"
      mkdir -p "$run_dir"
      (
        cd "$run_dir"
        run_with_optional_timeout "$CLI_TIMEOUT_SECS" "$out_file" "$err_file" "$SELFHOST_BIN" run
      )
      ;;
    test_unknown_flag)
      local test_dir="$tmpdir/test_unknown_flag_case"
      mkdir -p "$test_dir"
      (
        cd "$test_dir"
        run_with_optional_timeout "$CLI_TIMEOUT_SECS" "$out_file" "$err_file" "$SELFHOST_BIN" test --unknown-flag
      )
      ;;
    clean)
      local clean_dir="$tmpdir/clean_case"
      mkdir -p "$clean_dir/.with"
      (
        cd "$clean_dir"
        run_with_optional_timeout "$CLI_TIMEOUT_SECS" "$out_file" "$err_file" "$SELFHOST_BIN" clean
      )
      ;;
    *)
      echo "unknown cli key: $key" >"$err_file"
      return 2
      ;;
  esac
}

expect_mode_pass() {
  local mode="$1"
  local src="$2"
  if run_mode "$mode" "$src" "$tmpdir/out" "$tmpdir/err"; then
    echo "PASS(wave11-unit-${mode}-pass) $src"
  else
    echo "FAIL(wave11-unit-${mode}-pass) $src"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
  fi
  cleanup_artifacts "$src"
}

expect_mode_fail_msg() {
  local mode="$1"
  local src="$2"
  local msg="$3"
  if run_mode "$mode" "$src" "$tmpdir/out" "$tmpdir/err"; then
    echo "FAIL(wave11-unit-${mode}-fail) $src"
    failures=$((failures + 1))
    cleanup_artifacts "$src"
    return
  fi
  if ! grep -Fq "$msg" "$tmpdir/err"; then
    echo "FAIL(wave11-unit-${mode}-msg) $src"
    echo "expected message containing: $msg"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    cleanup_artifacts "$src"
    return
  fi
  echo "PASS(wave11-unit-${mode}-fail) $src"
  cleanup_artifacts "$src"
}

expect_cli_pass() {
  local key="$1"
  if run_cli_key "$key" "$tmpdir/out" "$tmpdir/err"; then
    echo "PASS(wave11-unit-cli-pass) $key"
  else
    echo "FAIL(wave11-unit-cli-pass) $key"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
  fi
}

expect_cli_fail() {
  local key="$1"
  if run_cli_key "$key" "$tmpdir/out" "$tmpdir/err"; then
    echo "FAIL(wave11-unit-cli-fail) $key"
    failures=$((failures + 1))
  else
    echo "PASS(wave11-unit-cli-fail) $key"
  fi
}

expect_mode_pass check "test/wave11/cases/driver_simple.w"
expect_mode_pass check "test/wave11/cases/imports/relative_root.w"
expect_mode_pass check "test/wave11/cases/imports/qualified_root.w"
expect_mode_pass check "test/wave11/cases/c_import_macro_constants_ok.w"
expect_mode_pass check "test/wave11/cases/c_import_macro_function_like_ok.w"
expect_mode_pass check "test/wave9/cases/runtime_linkage_sync_ok.w"
expect_mode_pass check "test/wave9/cases/runtime_linkage_async_ok.w"
expect_mode_fail_msg check "test/wave11/cases/imports/missing_root.w" "import module not found"
expect_mode_fail_msg check "test/wave11/cases/c_import_bad_header_fail.w" "failed to compile C header snippet"

expect_mode_pass build "test/wave11/cases/driver_simple.w"
expect_mode_pass build "test/wave11/cases/c_import_link_ok.w"
expect_mode_pass build "test/wave9/cases/runtime_linkage_sync_ok.w"
expect_mode_pass build "test/wave9/cases/runtime_linkage_async_ok.w"
expect_mode_fail_msg build "test/wave11/cases/c_import_link_missing_fail.w" "linking failed"

expect_mode_pass run "test/wave11/cases/driver_simple.w"
expect_mode_pass run "test/wave11/cases/imports/relative_root.w"
expect_mode_pass run "test/wave11/cases/imports/qualified_root.w"
expect_mode_pass run "test/wave11/cases/c_import_stdio_ok.w"
expect_mode_pass run "test/wave11/cases/c_import_link_ok.w"
expect_mode_pass run "test/wave9/cases/runtime_linkage_sync_ok.w"
expect_mode_pass run "test/wave9/cases/runtime_linkage_async_ok.w"

expect_mode_fail_msg test "test/wave11/cases/c_import_bad_header_fail.w" "test"
expect_mode_fail_msg test "test/wave11/cases/does_not_exist.w" "error:"

expect_cli_pass help
expect_cli_pass version
expect_cli_pass clean
expect_cli_fail unknown_command
expect_cli_fail build_missing_arg
expect_cli_fail run_missing_arg
expect_cli_fail test_unknown_flag

if [[ "$failures" -ne 0 ]]; then
  echo "wave11 driver unit tests: $failures failure(s)"
  exit 1
fi

echo "wave11 driver unit tests: PASS"
