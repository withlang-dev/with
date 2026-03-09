#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
source "${ROOT_DIR}/scripts/parity_states.sh"
source "${ROOT_DIR}/scripts/selfhost_runner.sh"

# selfhost seed checkpoint
STAGE0_BIN="${ROOT_DIR:-./}/src/main"
SELFHOST_BIN="./out/bin/with-stage2"
CORPUS_FILE="test/wave7/mir_corpus.txt"
VERIFY_COVERAGE_SCRIPT="scripts/verify_wave7_coverage.sh"
CHECK_TIMEOUT_SECS="${PARITY_CHECK_TIMEOUT_SECS:-60}"

echo "rebuilding self-host compiler for Wave 7 MIR parity..."
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
  echo "error: missing Wave 7 coverage verifier: $VERIFY_COVERAGE_SCRIPT"
  exit 1
fi
if ! "$VERIFY_COVERAGE_SCRIPT"; then
  exit 1
fi
if ! parity_validate_known_divergences "$CORPUS_FILE"; then
  exit 1
fi

run_check_with_timeout() {
  local bin="$1"
  local src="$2"
  local out="$3"
  local err="$4"
  runner_exec_capture "$CHECK_TIMEOUT_SECS" "$out" "$err" "$bin" check "$src" --dump-mir
}

run_check_with_retry() {
  local bin="$1"
  local src="$2"
  local out="$3"
  local err="$4"
  local attempts=0
  local rc=0
  while true; do
    run_check_with_timeout "$bin" "$src" "$out" "$err"
    rc=$?
    if [[ "$rc" -eq 0 ]]; then
      return 0
    fi
    attempts=$((attempts + 1))
    if [[ "$attempts" -ge 2 ]]; then
      return "$rc"
    fi
    # Transient timeout/kill under load: retry once.
    if [[ "$rc" -eq 124 || "$rc" -eq 137 || "$rc" -eq 143 ]]; then
      continue
    fi
    return "$rc"
  done
}

SELFHOST_BIN="$(prepare_selfhost_runner "$ROOT_DIR" "$SELFHOST_BIN")"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"; cleanup_selfhost_runner' EXIT

failures=0
known_divergences=0
processed=0
stage0_skips=0
declared_known_divergences="$(parity_kd_count "$CORPUS_FILE")"
used_kd_file="$tmpdir/used_known_divergences.txt"
touch "$used_kd_file"

probe_src="$(grep -v '^[[:space:]]*$' "$CORPUS_FILE" | grep -v '^#' | head -n 1 || true)"
if [[ -z "$probe_src" ]]; then
  echo "error: empty corpus: $CORPUS_FILE"
  exit 1
fi

stage0_supports_mir=0
if run_check_with_timeout "$STAGE0_BIN" "$probe_src" "$tmpdir/stage0_probe.out" "$tmpdir/stage0_probe.err"; then
  stage0_supports_mir=1
else
  if grep -q "unknown check flag '--dump-mir'" "$tmpdir/stage0_probe.err"; then
    stage0_supports_mir=0
  else
    echo "warning: stage0 --dump-mir probe failed for unexpected reason; continuing in self-host-only mode"
    cat "$tmpdir/stage0_probe.err"
    stage0_supports_mir=0
  fi
fi

if [[ "$stage0_supports_mir" -eq 1 ]]; then
  echo "stage0 supports --dump-mir; strict parity is enabled"
else
  echo "stage0 does not support --dump-mir; running deterministic self-host validation only"
fi

while IFS= read -r src; do
  [[ -z "$src" ]] && continue
  [[ "${src:0:1}" == "#" ]] && continue
  [[ "$src" == KNOWN_DIVERGENCE\|* ]] && continue

  if [[ ! -f "$src" ]]; then
    echo "FAIL(wave7-mir-parity-missing-source) $src"
    failures=$((failures + 1))
    continue
  fi

  processed=$((processed + 1))
  key="${src//\//__}"
  self_out_1="$tmpdir/${key}.selfhost.mir.1"
  self_out_2="$tmpdir/${key}.selfhost.mir.2"
  stage0_out="$tmpdir/${key}.stage0.mir"

  if ! run_check_with_retry "$SELFHOST_BIN" "$src" "$self_out_1" "$tmpdir/${key}.selfhost.err.1"; then
    echo "FAIL(wave7-mir-parity-selfhost-check) $src"
    cat "$tmpdir/${key}.selfhost.err.1"
    failures=$((failures + 1))
    continue
  fi

  if ! run_check_with_retry "$SELFHOST_BIN" "$src" "$self_out_2" "$tmpdir/${key}.selfhost.err.2"; then
    echo "FAIL(wave7-mir-parity-selfhost-recheck) $src"
    cat "$tmpdir/${key}.selfhost.err.2"
    failures=$((failures + 1))
    continue
  fi

  if ! diff -u "$self_out_1" "$self_out_2" >/dev/null; then
    echo "FAIL(wave7-mir-parity-nondeterministic-selfhost) $src"
    diff -u "$self_out_1" "$self_out_2" || true
    failures=$((failures + 1))
    continue
  fi

  if ! head -n 1 "$self_out_1" | grep -Eq '^mir module functions=[0-9]+$'; then
    echo "FAIL(wave7-mir-parity-format-header) $src"
    head -n 5 "$self_out_1" || true
    failures=$((failures + 1))
    continue
  fi

  kd_line="$(parity_kd_line_for_test "$CORPUS_FILE" "$src")"
  if [[ "$stage0_supports_mir" -eq 1 ]]; then
    if ! run_check_with_timeout "$STAGE0_BIN" "$src" "$stage0_out" "$tmpdir/${key}.stage0.err"; then
      echo "FAIL(wave7-mir-parity-stage0-check) $src"
      cat "$tmpdir/${key}.stage0.err"
      failures=$((failures + 1))
      continue
    fi

    if diff -u "$stage0_out" "$self_out_1" >/dev/null; then
      if [[ -n "$kd_line" ]]; then
        echo "FAIL(wave7-mir-parity-stale-known-divergence) $src"
        failures=$((failures + 1))
        continue
      fi
      echo "PASS(wave7-mir-parity) $src"
    else
      if [[ -n "$kd_line" ]]; then
        IFS='|' read -r _ kd_test kd_what kd_correct kd_why <<< "$kd_line"
        echo "KNOWN_DIVERGENCE(wave7-mir-parity) ${kd_test} what='${kd_what}' correct='${kd_correct}' why='${kd_why}'"
        echo "$kd_test" >> "$used_kd_file"
        known_divergences=$((known_divergences + 1))
      else
        echo "FAIL(wave7-mir-parity-diff) $src"
        diff -u "$stage0_out" "$self_out_1" || true
        failures=$((failures + 1))
      fi
    fi
  else
    if [[ -n "$kd_line" ]]; then
      echo "FAIL(wave7-mir-parity-known-divergence-uncheckable-without-stage0) $src"
      failures=$((failures + 1))
      continue
    fi
    echo "PASS(wave7-mir-determinism) $src"
    stage0_skips=$((stage0_skips + 1))
  fi
done < <(grep -v '^[[:space:]]*$' "$CORPUS_FILE" | grep -v '^#' | sort)

if [[ "$processed" -eq 0 ]]; then
  echo "error: empty corpus: $CORPUS_FILE"
  exit 1
fi
used_known_divergences="$(sort -u "$used_kd_file" | sed '/^$/d' | wc -l | tr -d ' ')"
if [[ "$declared_known_divergences" -ne "$used_known_divergences" ]]; then
  echo "FAIL(wave7-mir-parity-known-divergence-accounting) declared=$declared_known_divergences used=$used_known_divergences"
  failures=$((failures + 1))
fi

echo ""
echo "wave7 mir parity: processed=$processed failures=$failures known_divergences=$known_divergences stage0_skips=$stage0_skips"

if [[ "$failures" -ne 0 ]]; then
  echo "wave7 mir parity: FAIL"
  exit 1
fi

if [[ "$stage0_supports_mir" -eq 1 ]]; then
  echo "wave7 mir parity: PASS"
else
  echo "wave7 mir parity: PASS (self-host determinism only; stage0 --dump-mir unavailable)"
fi
