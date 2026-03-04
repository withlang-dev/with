#!/usr/bin/env bash
set -euo pipefail

# Compare structured diagnostics between two compiler binaries.
# Usage: compare_structured_diagnostics.sh <compiler_a> <compiler_b> <corpus_file>
#
# For each entry in the corpus:
#   - Run both compilers in check mode
#   - Extract and normalize diagnostic lines from stderr
#   - Compare diagnostic class and count
#   - Report PASS/FAIL/KNOWN_DIVERGENCE

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/selfhost_runner.sh"
source "${ROOT_DIR}/scripts/parity_states.sh"

COMPILER_A="${1:?usage: compare_structured_diagnostics.sh <compiler_a> <compiler_b> <corpus_file>}"
COMPILER_B="${2:?usage: compare_structured_diagnostics.sh <compiler_a> <compiler_b> <corpus_file>}"
CORPUS_FILE="${3:?usage: compare_structured_diagnostics.sh <compiler_a> <compiler_b> <corpus_file>}"

CHECK_TIMEOUT_SECS="${FIXPOINT_CHECK_TIMEOUT_SECS:-60}"

normalize_diagnostics() {
  local err_file="$1"
  # Strip file paths to basename, strip column numbers, lowercase
  grep -E '^(error|warning):' "$err_file" 2>/dev/null \
  | sed -E \
    -e 's|[^ ]*\/([^/:]+):([0-9]+):[0-9]+|\1:\2|g' \
    -e 's/[[:space:]]+/ /g' \
    -e 's/^ //' \
    -e 's/ $//' \
  | tr '[:upper:]' '[:lower:]' \
  | sort \
  || true
}

count_by_severity() {
  local err_file="$1"
  local severity="$2"
  grep -c "^${severity}:" "$err_file" 2>/dev/null || echo "0"
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0
processed=0
known_divergences=0

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  [[ "${line:0:1}" == "#" ]] && continue
  [[ "$line" == KNOWN_DIVERGENCE\|* ]] && continue
  [[ "$line" != *"|"* ]] && continue

  mode="${line%%|*}"
  src="${line#*|}"

  if [[ ! -f "$src" ]]; then
    continue
  fi

  processed=$((processed + 1))
  key="diag__${src//\//__}"

  a_out="$tmpdir/${key}.a.out"
  a_err="$tmpdir/${key}.a.err"
  b_out="$tmpdir/${key}.b.out"
  b_err="$tmpdir/${key}.b.err"

  a_rc=0
  runner_exec_capture "$CHECK_TIMEOUT_SECS" "$a_out" "$a_err" "$COMPILER_A" check "$src" || a_rc=$?

  b_rc=0
  runner_exec_capture "$CHECK_TIMEOUT_SECS" "$b_out" "$b_err" "$COMPILER_B" check "$src" || b_rc=$?

  # Compare exit codes
  if [[ "$a_rc" -ne "$b_rc" ]]; then
    kd_line="$(parity_mode_kd_line_for_entry "$CORPUS_FILE" "$mode" "$src")"
    if [[ -n "$kd_line" ]]; then
      echo "KNOWN_DIVERGENCE(fixpoint-diag) ${mode}|${src} stage2_rc=$a_rc stage3_rc=$b_rc"
      known_divergences=$((known_divergences + 1))
    else
      echo "FAIL(fixpoint-diag-exit-code) ${mode}|${src} stage2_rc=$a_rc stage3_rc=$b_rc"
      failures=$((failures + 1))
    fi
    continue
  fi

  # Compare error/warning counts
  a_errors="$(count_by_severity "$a_err" "error")"
  b_errors="$(count_by_severity "$b_err" "error")"
  a_warnings="$(count_by_severity "$a_err" "warning")"
  b_warnings="$(count_by_severity "$b_err" "warning")"

  if [[ "$a_errors" -ne "$b_errors" || "$a_warnings" -ne "$b_warnings" ]]; then
    kd_line="$(parity_mode_kd_line_for_entry "$CORPUS_FILE" "$mode" "$src")"
    if [[ -n "$kd_line" ]]; then
      echo "KNOWN_DIVERGENCE(fixpoint-diag) ${mode}|${src} errors=$a_errors/$b_errors warnings=$a_warnings/$b_warnings"
      known_divergences=$((known_divergences + 1))
    else
      echo "FAIL(fixpoint-diag-count) ${mode}|${src} errors=$a_errors/$b_errors warnings=$a_warnings/$b_warnings"
      failures=$((failures + 1))
    fi
    continue
  fi

  # Compare normalized diagnostic text
  a_norm="$tmpdir/${key}.a.diag.norm"
  b_norm="$tmpdir/${key}.b.diag.norm"
  normalize_diagnostics "$a_err" > "$a_norm"
  normalize_diagnostics "$b_err" > "$b_norm"

  if ! diff -u "$a_norm" "$b_norm" >/dev/null 2>&1; then
    kd_line="$(parity_mode_kd_line_for_entry "$CORPUS_FILE" "$mode" "$src")"
    if [[ -n "$kd_line" ]]; then
      echo "KNOWN_DIVERGENCE(fixpoint-diag) ${mode}|${src}"
      known_divergences=$((known_divergences + 1))
    else
      echo "FAIL(fixpoint-diag-diff) ${mode}|${src}"
      failures=$((failures + 1))
    fi
    continue
  fi

  echo "PASS(fixpoint-diag) ${mode}|${src}"
done < "$CORPUS_FILE"

echo ""
echo "fixpoint diagnostic comparison: processed=$processed failures=$failures known_divergences=$known_divergences"

if [[ "$failures" -ne 0 ]]; then
  echo "fixpoint diagnostic comparison: FAIL"
  exit 1
fi

echo "fixpoint diagnostic comparison: PASS"
