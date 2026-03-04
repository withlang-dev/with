#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
source "${ROOT_DIR}/scripts/parity_states.sh"
source "${ROOT_DIR}/scripts/selfhost_runner.sh"

STAGE0_BIN="${ROOT_DIR}/bootstrap/zig-out/bin/with"
SELFHOST_BIN="${ROOT_DIR}/with-stage2"
CORPUS_FILE="test/wave11/driver_corpus.txt"
VERIFY_COVERAGE_SCRIPT="scripts/verify_wave11_coverage.sh"
TIMEOUT_BIN="$(command -v timeout || true)"
RUN_TIMEOUT_SECS=25
CLI_TIMEOUT_SECS=25
MODE_TIMEOUT_SECS=40

echo "building bootstrap compiler for Wave 11 driver parity..."
(
  cd bootstrap
  zig build -Doptimize=Debug >/dev/null
)

echo "rebuilding self-host compiler for Wave 11 driver parity..."
./scripts/rebuild_selfhost.sh stage2 >/dev/null

if [[ ! -x "$STAGE0_BIN" ]]; then
  echo "error: missing Stage0 compiler: $STAGE0_BIN"
  exit 1
fi
if [[ ! -x "$SELFHOST_BIN" ]]; then
  echo "error: missing self-host compiler: $SELFHOST_BIN"
  exit 1
fi
if [[ ! -f "$CORPUS_FILE" ]]; then
  echo "error: missing corpus file: $CORPUS_FILE"
  exit 1
fi
if [[ ! -x "$VERIFY_COVERAGE_SCRIPT" ]]; then
  echo "error: missing Wave 11 coverage verifier: $VERIFY_COVERAGE_SCRIPT"
  exit 1
fi
if ! "$VERIFY_COVERAGE_SCRIPT"; then
  exit 1
fi
if ! parity_validate_known_divergences_mode_allowed "$CORPUS_FILE" check build run test cli; then
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
  local bin="$1"
  local mode="$2"
  local src="$3"
  local out_file="$4"
  local err_file="$5"

  if [[ -n "$TIMEOUT_BIN" ]]; then
    if [[ "$mode" == "run" ]]; then
      "$TIMEOUT_BIN" -k 5 "$RUN_TIMEOUT_SECS" "$bin" "$mode" "$src" >"$out_file" 2>"$err_file"
      return $?
    fi
    "$TIMEOUT_BIN" -k 5 "$MODE_TIMEOUT_SECS" "$bin" "$mode" "$src" >"$out_file" 2>"$err_file"
    return $?
  fi

  "$bin" "$mode" "$src" >"$out_file" 2>"$err_file"
}

run_cli_cmd() {
  local timeout_secs="$1"
  shift
  if [[ -n "$TIMEOUT_BIN" ]]; then
    "$TIMEOUT_BIN" -k 5 "$timeout_secs" "$@"
    return $?
  fi
  "$@"
}

run_cli_key() {
  local bin="$1"
  local key="$2"
  local out_file="$3"
  local err_file="$4"

  case "$key" in
    help)
      run_cli_cmd "$CLI_TIMEOUT_SECS" "$bin" help >"$out_file" 2>"$err_file"
      ;;
    version)
      run_cli_cmd "$CLI_TIMEOUT_SECS" "$bin" version >"$out_file" 2>"$err_file"
      ;;
    unknown_command)
      run_cli_cmd "$CLI_TIMEOUT_SECS" "$bin" does_not_exist >"$out_file" 2>"$err_file"
      ;;
    build_missing_arg)
      local build_dir="$tmpdir/build_missing_arg_${bin##*/}_$RANDOM"
      mkdir -p "$build_dir"
      (
        cd "$build_dir"
        run_cli_cmd "$CLI_TIMEOUT_SECS" "$bin" build >"$out_file" 2>"$err_file"
      )
      ;;
    run_missing_arg)
      local run_dir="$tmpdir/run_missing_arg_${bin##*/}_$RANDOM"
      mkdir -p "$run_dir"
      (
        cd "$run_dir"
        run_cli_cmd "$CLI_TIMEOUT_SECS" "$bin" run >"$out_file" 2>"$err_file"
      )
      ;;
    test_unknown_flag)
      local test_dir="$tmpdir/test_unknown_flag_${bin##*/}_$RANDOM"
      mkdir -p "$test_dir"
      (
        cd "$test_dir"
        run_cli_cmd "$CLI_TIMEOUT_SECS" "$bin" test --unknown-flag >"$out_file" 2>"$err_file"
      )
      ;;
    clean)
      local clean_dir="$tmpdir/clean_${bin##*/}_$RANDOM"
      mkdir -p "$clean_dir/.with"
      (
        cd "$clean_dir"
        run_cli_cmd "$CLI_TIMEOUT_SECS" "$bin" clean >"$out_file" 2>"$err_file"
      )
      ;;
    *)
      echo "unknown cli key: $key" >"$err_file"
      return 2
      ;;
  esac
}

failures=0
known_divergences=0
processed=0
declared_known_divergences="$(parity_mode_kd_count "$CORPUS_FILE")"
used_kd_file="$tmpdir/used_known_divergences.txt"
touch "$used_kd_file"

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  [[ "${line:0:1}" == "#" ]] && continue
  [[ "$line" == KNOWN_DIVERGENCE\|* ]] && continue

  if [[ "$line" != *"|"* ]]; then
    echo "FAIL(wave11-driver-parity-entry-format) $line"
    failures=$((failures + 1))
    continue
  fi

  mode="${line%%|*}"
  entry="${line#*|}"
  if [[ "$mode" != "check" && "$mode" != "build" && "$mode" != "run" && "$mode" != "test" && "$mode" != "cli" ]]; then
    echo "FAIL(wave11-driver-parity-entry-mode) $line"
    failures=$((failures + 1))
    continue
  fi

  if [[ "$mode" == "check" || "$mode" == "build" || "$mode" == "run" ]]; then
    if [[ ! -f "$entry" ]]; then
      echo "FAIL(wave11-driver-parity-missing-source) ${mode}|${entry}"
      failures=$((failures + 1))
      continue
    fi
  fi

  processed=$((processed + 1))
  key="${mode}__${entry//\//__}"
  kd_line="$(parity_mode_kd_line_for_entry "$CORPUS_FILE" "$mode" "$entry")"

  stage0_out="$tmpdir/${key}.stage0.out"
  stage0_err="$tmpdir/${key}.stage0.err"
  self_out_1="$tmpdir/${key}.selfhost.out.1"
  self_err_1="$tmpdir/${key}.selfhost.err.1"
  self_out_2="$tmpdir/${key}.selfhost.out.2"
  self_err_2="$tmpdir/${key}.selfhost.err.2"

  stage0_rc=0
  if [[ "$mode" == "cli" ]]; then
    run_cli_key "$STAGE0_BIN" "$entry" "$stage0_out" "$stage0_err" || stage0_rc=$?
  else
    run_mode "$STAGE0_BIN" "$mode" "$entry" "$stage0_out" "$stage0_err" || stage0_rc=$?
  fi

  self_rc_1=0
  if [[ "$mode" == "cli" ]]; then
    run_cli_key "$SELFHOST_BIN" "$entry" "$self_out_1" "$self_err_1" || self_rc_1=$?
  else
    run_mode "$SELFHOST_BIN" "$mode" "$entry" "$self_out_1" "$self_err_1" || self_rc_1=$?
  fi

  self_rc_2=0
  if [[ "$mode" == "cli" ]]; then
    run_cli_key "$SELFHOST_BIN" "$entry" "$self_out_2" "$self_err_2" || self_rc_2=$?
  else
    run_mode "$SELFHOST_BIN" "$mode" "$entry" "$self_out_2" "$self_err_2" || self_rc_2=$?
  fi

  if [[ "$mode" == "check" || "$mode" == "build" || "$mode" == "run" || "$mode" == "test" ]]; then
    cleanup_artifacts "$entry"
  fi

  if [[ "$self_rc_1" -ne "$self_rc_2" ]]; then
    echo "FAIL(wave11-driver-parity-nondeterministic-selfhost-status) ${mode}|${entry} rc1=$self_rc_1 rc2=$self_rc_2"
    failures=$((failures + 1))
    continue
  fi
  if ! diff -u "$self_out_1" "$self_out_2" >/dev/null; then
    echo "FAIL(wave11-driver-parity-nondeterministic-selfhost-stdout) ${mode}|${entry}"
    failures=$((failures + 1))
    continue
  fi
  if ! diff -u "$self_err_1" "$self_err_2" >/dev/null; then
    echo "FAIL(wave11-driver-parity-nondeterministic-selfhost-stderr) ${mode}|${entry}"
    failures=$((failures + 1))
    continue
  fi

  is_match=0
  if [[ "$mode" == "run" ]]; then
    if [[ "$stage0_rc" -eq "$self_rc_1" ]] && diff -u "$stage0_out" "$self_out_1" >/dev/null && diff -u "$stage0_err" "$self_err_1" >/dev/null; then
      is_match=1
    fi
  else
    # Wave 11 entry gate currently focuses on command/status parity for non-run modes.
    if [[ "$stage0_rc" -eq "$self_rc_1" ]]; then
      is_match=1
    fi
  fi

  if [[ "$is_match" -eq 1 ]]; then
    if [[ -n "$kd_line" ]]; then
      echo "FAIL(wave11-driver-parity-stale-known-divergence) ${mode}|${entry}"
      failures=$((failures + 1))
      continue
    fi
    echo "PASS(wave11-driver-parity) ${mode}|${entry}"
    continue
  fi

  if [[ -n "$kd_line" ]]; then
    IFS='|' read -r _ kd_mode kd_entry kd_what kd_correct kd_why <<< "$kd_line"
    echo "KNOWN_DIVERGENCE(wave11-driver-parity) ${kd_mode}|${kd_entry} what='${kd_what}' correct='${kd_correct}' why='${kd_why}' stage0_rc=$stage0_rc selfhost_rc=$self_rc_1"
    echo "${kd_mode}|${kd_entry}" >> "$used_kd_file"
    known_divergences=$((known_divergences + 1))
  else
    echo "FAIL(wave11-driver-parity-diff) ${mode}|${entry} stage0_rc=$stage0_rc selfhost_rc=$self_rc_1"
    echo "  stage0 stdout: $(head -n 1 "$stage0_out" || true)"
    echo "  selfhost stdout: $(head -n 1 "$self_out_1" || true)"
    echo "  stage0 stderr: $(head -n 1 "$stage0_err" || true)"
    echo "  selfhost stderr: $(head -n 1 "$self_err_1" || true)"
    failures=$((failures + 1))
  fi
done < "$CORPUS_FILE"

if [[ "$processed" -eq 0 ]]; then
  echo "error: empty corpus: $CORPUS_FILE"
  exit 1
fi

used_known_divergences="$(sort -u "$used_kd_file" | sed '/^$/d' | wc -l | tr -d ' ')"
if [[ "$declared_known_divergences" -ne "$used_known_divergences" ]]; then
  echo "FAIL(wave11-driver-parity-known-divergence-accounting) declared=$declared_known_divergences used=$used_known_divergences"
  failures=$((failures + 1))
fi

echo ""
echo "wave11 driver parity: processed=$processed failures=$failures known_divergences=$known_divergences"

if [[ "$failures" -ne 0 ]]; then
  echo "wave11 driver parity: FAIL"
  exit 1
fi

echo "wave11 driver parity: PASS"
