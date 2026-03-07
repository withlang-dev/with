#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
source "${ROOT_DIR}/scripts/parity_states.sh"
source "${ROOT_DIR}/scripts/selfhost_runner.sh"

STAGE0_BIN="./bootstrap/zig-out/bin/with"
SELFHOST_BIN="./out/bin/with-stage2"
CORPUS_FILE="test/wave8/borrow_corpus.txt"
VERIFY_COVERAGE_SCRIPT="scripts/verify_wave8_coverage.sh"
CHECK_TIMEOUT_SECS="${PARITY_CHECK_TIMEOUT_SECS:-60}"

echo "building bootstrap compiler for Wave 8 borrow parity..."
(
  cd bootstrap
  zig build -Doptimize=Debug >/dev/null
)

echo "rebuilding self-host compiler for Wave 8 borrow parity..."
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
  echo "error: missing Wave 8 coverage verifier: $VERIFY_COVERAGE_SCRIPT"
  exit 1
fi
if ! "$VERIFY_COVERAGE_SCRIPT"; then
  exit 1
fi
if ! parity_validate_known_divergences "$CORPUS_FILE"; then
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

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"; cleanup_selfhost_runner' EXIT

failures=0
known_divergences=0
processed=0
declared_known_divergences="$(parity_kd_count "$CORPUS_FILE")"
used_kd_file="$tmpdir/used_known_divergences.txt"
touch "$used_kd_file"

while IFS= read -r src; do
  [[ -z "$src" ]] && continue
  [[ "${src:0:1}" == "#" ]] && continue
  [[ "$src" == KNOWN_DIVERGENCE\|* ]] && continue

  if [[ ! -f "$src" ]]; then
    echo "FAIL(wave8-borrow-parity-missing-source) $src"
    failures=$((failures + 1))
    continue
  fi

  processed=$((processed + 1))
  key="${src//\//__}"
  kd_line="$(parity_kd_line_for_test "$CORPUS_FILE" "$src")"

  stage0_err="$tmpdir/${key}.stage0.err"
  self_err_1="$tmpdir/${key}.selfhost.err.1"
  self_err_2="$tmpdir/${key}.selfhost.err.2"

  stage0_rc=0
  runner_exec_capture "$CHECK_TIMEOUT_SECS" /dev/null "$stage0_err" "$STAGE0_BIN" check "$src" || stage0_rc=$?

  self_rc_1=0
  runner_exec_capture "$CHECK_TIMEOUT_SECS" /dev/null "$self_err_1" "$SELFHOST_BIN" check "$src" || self_rc_1=$?

  self_rc_2=0
  runner_exec_capture "$CHECK_TIMEOUT_SECS" /dev/null "$self_err_2" "$SELFHOST_BIN" check "$src" || self_rc_2=$?

  if [[ "$self_rc_1" -ne "$self_rc_2" ]]; then
    echo "FAIL(wave8-borrow-parity-nondeterministic-selfhost-status) $src rc1=$self_rc_1 rc2=$self_rc_2"
    failures=$((failures + 1))
    continue
  fi

  if ! diff -u "$self_err_1" "$self_err_2" >/dev/null; then
    echo "FAIL(wave8-borrow-parity-nondeterministic-selfhost-diagnostics) $src"
    diff -u "$self_err_1" "$self_err_2" || true
    failures=$((failures + 1))
    continue
  fi

  is_match=0
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

  if [[ "$is_match" -eq 1 ]]; then
    if [[ -n "$kd_line" ]]; then
      echo "FAIL(wave8-borrow-parity-stale-known-divergence) $src"
      failures=$((failures + 1))
      continue
    fi
    echo "PASS(wave8-borrow-parity) $src"
    continue
  fi

  if [[ -n "$kd_line" ]]; then
    IFS='|' read -r _ kd_test kd_what kd_correct kd_why <<< "$kd_line"
    echo "KNOWN_DIVERGENCE(wave8-borrow-parity) ${kd_test} what='${kd_what}' correct='${kd_correct}' why='${kd_why}' stage0_rc=$stage0_rc selfhost_rc=$self_rc_1"
    echo "$kd_test" >> "$used_kd_file"
    known_divergences=$((known_divergences + 1))
  else
    echo "FAIL(wave8-borrow-parity-diff) $src stage0_rc=$stage0_rc selfhost_rc=$self_rc_1"
    echo "  stage0: $(extract_primary_diagnostic "$stage0_err")"
    echo "  selfhost: $(extract_primary_diagnostic "$self_err_1")"
    failures=$((failures + 1))
  fi
done < <(grep -v '^[[:space:]]*$' "$CORPUS_FILE" | grep -v '^#' | sort)

if [[ "$processed" -eq 0 ]]; then
  echo "error: empty corpus: $CORPUS_FILE"
  exit 1
fi

used_known_divergences="$(sort -u "$used_kd_file" | sed '/^$/d' | wc -l | tr -d ' ')"
if [[ "$declared_known_divergences" -ne "$used_known_divergences" ]]; then
  echo "FAIL(wave8-borrow-parity-known-divergence-accounting) declared=$declared_known_divergences used=$used_known_divergences"
  failures=$((failures + 1))
fi

echo ""
echo "wave8 borrow parity: processed=$processed failures=$failures known_divergences=$known_divergences"

if [[ "$failures" -ne 0 ]]; then
  echo "wave8 borrow parity: FAIL"
  exit 1
fi

echo "wave8 borrow parity: PASS"
