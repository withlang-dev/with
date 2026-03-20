#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
source "${ROOT_DIR}/scripts/selfhost_runner.sh"

SELFHOST_BIN="${ROOT_DIR}/out/bin/with-stage2"
CHECK_TIMEOUT_SECS="${PARITY_CHECK_TIMEOUT_SECS:-60}"
RUN_TIMEOUT_SECS="${PARITY_RUN_TIMEOUT_SECS:-25}"
CLI_TIMEOUT_SECS="${PARITY_CLI_TIMEOUT_SECS:-25}"
EXPECTED_VERSION="with $("${ROOT_DIR}/scripts/resolve_version.sh")"

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

expect_cli_stdout() {
  local key="$1"
  local expected="$2"
  if ! run_cli_key "$key" "$tmpdir/out" "$tmpdir/err"; then
    echo "FAIL(wave11-unit-cli-stdout-run) $key"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi
  local actual=""
  actual="$(tr -d '\r' < "$tmpdir/out")"
  actual="${actual%$'\n'}"
  if [[ "$actual" != "$expected" ]]; then
    echo "FAIL(wave11-unit-cli-stdout) $key"
    echo "expected: $expected"
    echo "actual: $actual"
    failures=$((failures + 1))
    return
  fi
  echo "PASS(wave11-unit-cli-stdout) $key"
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

expect_check_dump_contains() {
  local label="$1"
  local needle="$2"
  shift 2
  if ! run_with_optional_timeout "$CHECK_TIMEOUT_SECS" "$tmpdir/out" "$tmpdir/err" "$SELFHOST_BIN" check --dump-resolved "$@"; then
    echo "FAIL(wave11-unit-prelude-${label}-run)"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi
  if ! grep -Fq "$needle" "$tmpdir/out"; then
    echo "FAIL(wave11-unit-prelude-${label}-contains)"
    echo "expected resolved dump to contain: $needle"
    cat "$tmpdir/out" || true
    failures=$((failures + 1))
    return
  fi
  echo "PASS(wave11-unit-prelude-${label})"
}

expect_check_dump_not_contains() {
  local label="$1"
  local needle="$2"
  shift 2
  if ! run_with_optional_timeout "$CHECK_TIMEOUT_SECS" "$tmpdir/out" "$tmpdir/err" "$SELFHOST_BIN" check --dump-resolved "$@"; then
    echo "FAIL(wave11-unit-prelude-${label}-run)"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi
  if grep -Fq "$needle" "$tmpdir/out"; then
    echo "FAIL(wave11-unit-prelude-${label}-not-contains)"
    echo "unexpected resolved dump match: $needle"
    cat "$tmpdir/out" || true
    failures=$((failures + 1))
    return
  fi
  echo "PASS(wave11-unit-prelude-${label})"
}

expect_embedded_std_standalone_check_pass() {
  local standalone_dir="$tmpdir/standalone_compiler"
  local foreign_cwd="$tmpdir/foreign_cwd"
  local foreign_src="$tmpdir/foreign_src/hello.w"
  mkdir -p "$standalone_dir" "$foreign_cwd" "$(dirname "$foreign_src")"

  cp "$SELFHOST_BIN" "$standalone_dir/with"
  chmod +x "$standalone_dir/with"

  local runner_runtime=""
  runner_runtime="$(cd "$(dirname "$SELFHOST_BIN")" && pwd)/runtime/libwith_llvm_bridge.dylib"
  if [[ -f "$runner_runtime" ]]; then
    mkdir -p "$standalone_dir/runtime"
    cp "$runner_runtime" "$standalone_dir/runtime/libwith_llvm_bridge.dylib"
  elif [[ -f "$ROOT_DIR/out/lib/libwith_llvm_bridge.dylib" ]]; then
    mkdir -p "$standalone_dir/runtime"
    cp "$ROOT_DIR/out/lib/libwith_llvm_bridge.dylib" "$standalone_dir/runtime/libwith_llvm_bridge.dylib"
  fi

  cat >"$foreign_src" <<'EOF'
fn main:
    println("ok")
EOF

  if (
    cd "$foreign_cwd"
    run_with_optional_timeout "$CHECK_TIMEOUT_SECS" "$tmpdir/out" "$tmpdir/err" "$standalone_dir/with" check "$foreign_src"
  ); then
    echo "PASS(wave11-unit-embedded-std-standalone-check)"
  else
    echo "FAIL(wave11-unit-embedded-std-standalone-check)"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
  fi
}

expect_mode_pass check "test/wave11/cases/driver_simple.w"
expect_mode_pass check "test/wave11/cases/imports/relative_root.w"
expect_mode_pass check "test/wave11/cases/imports/qualified_root.w"
expect_mode_pass check "test/wave11/cases/c_import_macro_constants_ok.w"
expect_mode_pass check "test/wave11/cases/c_import_macro_function_like_ok.w"
expect_mode_pass check "test/wave9/cases/runtime_linkage_sync_ok.w"
expect_mode_pass check "test/wave9/cases/runtime_linkage_async_ok.w"
expect_mode_pass check "test/wave11/cases/prelude/local_shadow_max64.w"
expect_mode_pass check "test/wave11/cases/prelude/explicit_shadow_mod.w"
expect_mode_pass check "test/wave11/cases/prelude/explicit_shadow_root.w"
expect_mode_pass check "test/wave11/cases/prelude/pinned_root.w"
expect_mode_fail_msg check "test/wave11/cases/imports/missing_root.w" "import module not found"
expect_mode_fail_msg check "test/wave11/cases/c_import_bad_header_fail.w" "failed to compile C header snippet"

expect_check_dump_contains "full" "path=<embedded-std>/std/prelude.w" "test/wave11/cases/prelude/simple_root.w"
expect_check_dump_contains "full-iter" "path=<embedded-std>/std/iter.w" "test/wave11/cases/prelude/simple_root.w"
expect_check_dump_contains "full-fs" "path=<embedded-std>/std/fs.w" "test/wave11/cases/prelude/simple_root.w"
expect_check_dump_contains "full-process" "path=<embedded-std>/std/process.w" "test/wave11/cases/prelude/simple_root.w"
expect_check_dump_contains "core" "path=<embedded-std>/std/prelude_core.w" "--prelude=core" "test/wave11/cases/prelude/simple_root.w"
expect_check_dump_not_contains "core-iter" "path=<embedded-std>/std/iter.w" "--prelude=core" "test/wave11/cases/prelude/simple_root.w"
expect_check_dump_not_contains "core-fs" "path=<embedded-std>/std/fs.w" "--prelude=core" "test/wave11/cases/prelude/simple_root.w"
expect_check_dump_not_contains "core-process" "path=<embedded-std>/std/process.w" "--prelude=core" "test/wave11/cases/prelude/simple_root.w"
expect_check_dump_not_contains "none" "path=<embedded-std>/std/prelude" "--no-prelude" "test/wave11/cases/prelude/simple_root.w"
expect_check_dump_not_contains "none-math" "path=<embedded-std>/std/math.w" "--no-prelude" "test/wave11/cases/prelude/simple_root.w"
expect_check_dump_not_contains "none-process" "path=<embedded-std>/std/process.w" "--no-prelude" "test/wave11/cases/prelude/simple_root.w"
expect_check_dump_not_contains "freestanding" "path=<embedded-std>/std/prelude" "--freestanding" "test/wave11/cases/prelude/simple_root.w"
expect_check_dump_not_contains "freestanding-math" "path=<embedded-std>/std/math.w" "--freestanding" "test/wave11/cases/prelude/simple_root.w"
expect_check_dump_not_contains "freestanding-process" "path=<embedded-std>/std/process.w" "--freestanding" "test/wave11/cases/prelude/simple_root.w"
expect_embedded_std_standalone_check_pass

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
expect_cli_stdout version "$EXPECTED_VERSION"
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
