#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
source "${ROOT_DIR}/scripts/parity_states.sh"
source "${ROOT_DIR}/scripts/selfhost_runner.sh"

STAGE0_BIN="./bootstrap/zig-out/bin/with"
SELFHOST_BIN="./out/bin/with-stage2"
CORPUS_FILE="test/wave9/async_corpus.txt"
VERIFY_COVERAGE_SCRIPT="scripts/verify_wave9_coverage.sh"
CHECK_TIMEOUT_SECS="${PARITY_CHECK_TIMEOUT_SECS:-60}"
RUN_TIMEOUT_SECS="${PARITY_RUN_TIMEOUT_SECS:-25}"

echo "building bootstrap compiler for Wave 9 async parity..."
(
  cd bootstrap
  zig build -Doptimize=Debug >/dev/null
)

echo "rebuilding self-host compiler for Wave 9 async parity..."
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
  echo "error: missing Wave 9 coverage verifier: $VERIFY_COVERAGE_SCRIPT"
  exit 1
fi
if ! "$VERIFY_COVERAGE_SCRIPT"; then
  exit 1
fi
if ! parity_validate_known_divergences_mode "$CORPUS_FILE"; then
  exit 1
fi

SELFHOST_BIN="$(prepare_selfhost_runner "$ROOT_DIR" "$SELFHOST_BIN")"

extract_primary_diagnostic() {
  local file="$1"
  local line=""
  line="$(grep -m1 '^error:' "$file" || true)"
  if [[ -z "$line" ]]; then
    line="$(grep -m1 '^warning:' "$file" || true)"
  fi
  if [[ -z "$line" ]]; then
    line="$(head -n 1 "$file" || true)"
  fi
  echo "$line" | tr -d '\r' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'
}

extract_primary_warning() {
  local file="$1"
  local line=""
  line="$(grep -m1 '^warning:' "$file" || true)"
  echo "$line" | tr -d '\r' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'
}

run_compiler_mode() {
  local bin="$1"
  local mode="$2"
  local src="$3"
  local out_file="$4"
  local err_file="$5"
  local timeout_secs="$CHECK_TIMEOUT_SECS"

  if [[ "$mode" == "run" ]]; then
    timeout_secs="$RUN_TIMEOUT_SECS"
  fi

  runner_exec_capture "$timeout_secs" "$out_file" "$err_file" "$bin" "$mode" "$src"
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"; cleanup_selfhost_runner' EXIT

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
    echo "FAIL(wave9-async-parity-entry-format) $line"
    failures=$((failures + 1))
    continue
  fi

  mode="${line%%|*}"
  src="${line#*|}"
  if [[ "$mode" != "check" && "$mode" != "build" && "$mode" != "run" ]]; then
    echo "FAIL(wave9-async-parity-entry-mode) $line"
    failures=$((failures + 1))
    continue
  fi
  if [[ ! -f "$src" ]]; then
    echo "FAIL(wave9-async-parity-missing-source) ${mode}|${src}"
    failures=$((failures + 1))
    continue
  fi

  processed=$((processed + 1))
  key="${mode}__${src//\//__}"
  kd_line="$(parity_mode_kd_line_for_entry "$CORPUS_FILE" "$mode" "$src")"

  stage0_out="$tmpdir/${key}.stage0.out"
  stage0_err="$tmpdir/${key}.stage0.err"
  self_out_1="$tmpdir/${key}.selfhost.out.1"
  self_err_1="$tmpdir/${key}.selfhost.err.1"
  self_out_2="$tmpdir/${key}.selfhost.out.2"
  self_err_2="$tmpdir/${key}.selfhost.err.2"

  stage0_rc=0
  run_compiler_mode "$STAGE0_BIN" "$mode" "$src" "$stage0_out" "$stage0_err" || stage0_rc=$?

  self_rc_1=0
  run_compiler_mode "$SELFHOST_BIN" "$mode" "$src" "$self_out_1" "$self_err_1" || self_rc_1=$?

  self_rc_2=0
  run_compiler_mode "$SELFHOST_BIN" "$mode" "$src" "$self_out_2" "$self_err_2" || self_rc_2=$?

  if [[ "$self_rc_1" -ne "$self_rc_2" ]]; then
    echo "FAIL(wave9-async-parity-nondeterministic-selfhost-status) ${mode}|${src} rc1=$self_rc_1 rc2=$self_rc_2"
    failures=$((failures + 1))
    continue
  fi
  if ! diff -u "$self_out_1" "$self_out_2" >/dev/null; then
    echo "FAIL(wave9-async-parity-nondeterministic-selfhost-stdout) ${mode}|${src}"
    failures=$((failures + 1))
    continue
  fi
  if ! diff -u "$self_err_1" "$self_err_2" >/dev/null; then
    echo "FAIL(wave9-async-parity-nondeterministic-selfhost-stderr) ${mode}|${src}"
    failures=$((failures + 1))
    continue
  fi

  is_match=0
  if [[ "$mode" == "run" ]]; then
    if [[ "$stage0_rc" -eq "$self_rc_1" ]] && diff -u "$stage0_out" "$self_out_1" >/dev/null && diff -u "$stage0_err" "$self_err_1" >/dev/null; then
      is_match=1
    fi
  else
    if [[ "$stage0_rc" -eq "$self_rc_1" ]]; then
      if [[ "$stage0_rc" -eq 0 ]]; then
        stage0_warn="$(extract_primary_warning "$stage0_err")"
        self_warn="$(extract_primary_warning "$self_err_1")"
        if [[ "$stage0_warn" == "$self_warn" ]]; then
          is_match=1
        fi
      else
        stage0_diag="$(extract_primary_diagnostic "$stage0_err")"
        self_diag="$(extract_primary_diagnostic "$self_err_1")"
        if [[ "$stage0_diag" == "$self_diag" ]]; then
          is_match=1
        fi
      fi
    fi
  fi

  if [[ "$is_match" -eq 1 ]]; then
    if [[ -n "$kd_line" ]]; then
      echo "FAIL(wave9-async-parity-stale-known-divergence) ${mode}|${src}"
      failures=$((failures + 1))
      continue
    fi
    echo "PASS(wave9-async-parity) ${mode}|${src}"
    continue
  fi

  if [[ -n "$kd_line" ]]; then
    IFS='|' read -r _ kd_mode kd_test kd_what kd_correct kd_why <<< "$kd_line"
    echo "KNOWN_DIVERGENCE(wave9-async-parity) ${kd_mode}|${kd_test} what='${kd_what}' correct='${kd_correct}' why='${kd_why}' stage0_rc=$stage0_rc selfhost_rc=$self_rc_1"
    echo "${kd_mode}|${kd_test}" >> "$used_kd_file"
    known_divergences=$((known_divergences + 1))
  else
    echo "FAIL(wave9-async-parity-diff) ${mode}|${src} stage0_rc=$stage0_rc selfhost_rc=$self_rc_1"
    if [[ "$mode" == "run" ]]; then
      echo "  stdout(stage0): $(head -n 1 "$stage0_out" || true)"
      echo "  stdout(selfhost): $(head -n 1 "$self_out_1" || true)"
      echo "  stderr(stage0): $(extract_primary_diagnostic "$stage0_err")"
      echo "  stderr(selfhost): $(extract_primary_diagnostic "$self_err_1")"
    else
      echo "  stage0: $(extract_primary_diagnostic "$stage0_err")"
      echo "  selfhost: $(extract_primary_diagnostic "$self_err_1")"
    fi
    failures=$((failures + 1))
  fi
done < "$CORPUS_FILE"

if [[ "$processed" -eq 0 ]]; then
  echo "error: empty corpus: $CORPUS_FILE"
  exit 1
fi

used_known_divergences="$(sort -u "$used_kd_file" | sed '/^$/d' | wc -l | tr -d ' ')"
if [[ "$declared_known_divergences" -ne "$used_known_divergences" ]]; then
  echo "FAIL(wave9-async-parity-known-divergence-accounting) declared=$declared_known_divergences used=$used_known_divergences"
  failures=$((failures + 1))
fi

echo ""
echo "wave9 async parity: processed=$processed failures=$failures known_divergences=$known_divergences"

if [[ "$failures" -ne 0 ]]; then
  echo "wave9 async parity: FAIL"
  exit 1
fi

echo "wave9 async parity: PASS"
