#!/usr/bin/env bash
set -euo pipefail

# Structurally compare LLVM IR output between two compiler binaries.
# Usage: compare_ir_structural.sh <compiler_a> <compiler_b> <corpus_file>
#
# For each ir|<path> entry in the corpus:
#   - Run both compilers in ir mode
#   - Normalize IR (strip comments, metadata, renumber SSA values)
#   - diff normalized outputs
#
# For each check|<path> entry:
#   - Run both compilers in check mode
#   - Compare diagnostic class and exit code
#
# Prints PASS/FAIL per entry. Exits 0 only if all entries pass.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/selfhost_runner.sh"

COMPILER_A="${1:?usage: compare_ir_structural.sh <compiler_a> <compiler_b> <corpus_file>}"
COMPILER_B="${2:?usage: compare_ir_structural.sh <compiler_a> <compiler_b> <corpus_file>}"
CORPUS_FILE="${3:?usage: compare_ir_structural.sh <compiler_a> <compiler_b> <corpus_file>}"

IR_TIMEOUT_SECS="${FIXPOINT_IR_TIMEOUT_SECS:-60}"
CHECK_TIMEOUT_SECS="${FIXPOINT_CHECK_TIMEOUT_SECS:-60}"

normalize_ir() {
  local input_file="$1"
  # Strip:
  #   - Lines starting with ; (comments)
  #   - source_filename metadata
  #   - !dbg metadata references
  #   - target datalayout/triple (may differ by build env)
  # Normalize:
  #   - %tmp.N and %N SSA value numbering → sequential
  #   - Trailing whitespace
  sed -E \
    -e '/^;/d' \
    -e '/^source_filename/d' \
    -e '/^target datalayout/d' \
    -e '/^target triple/d' \
    -e 's/, *!dbg ![0-9]+//g' \
    -e 's/!dbg ![0-9]+//g' \
    -e 's/[[:space:]]+$//' \
    "$input_file" \
  | awk '
    BEGIN { next_id = 0 }
    {
      line = $0
      while (match(line, /%tmp\.[0-9]+|%[0-9]+/)) {
        old = substr(line, RSTART, RLENGTH)
        if (!(old in remap)) {
          remap[old] = "%v" next_id
          next_id++
        }
        gsub(old, remap[old], line)
      }
      print line
    }
  '
}

normalize_check_output() {
  local err_file="$1"
  # Extract diagnostic lines, normalize paths to basename, strip columns
  sed -E \
    -e 's|[^ ]*\/([^/:]+):([0-9]+):[0-9]+|\1:\2|g' \
    -e 's/[[:space:]]+/ /g' \
    -e 's/^ //' \
    -e 's/ $//' \
    "$err_file" \
  | tr '[:upper:]' '[:lower:]'
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0
processed=0

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  [[ "${line:0:1}" == "#" ]] && continue
  [[ "$line" == KNOWN_DIVERGENCE\|* ]] && continue
  [[ "$line" != *"|"* ]] && continue

  mode="${line%%|*}"
  src="${line#*|}"

  if [[ "$mode" != "ir" && "$mode" != "check" ]]; then
    continue
  fi

  if [[ ! -f "$src" ]]; then
    echo "FAIL(fixpoint-ir-missing-source) ${mode}|${src}"
    failures=$((failures + 1))
    continue
  fi

  processed=$((processed + 1))
  key="${mode}__${src//\//__}"

  a_out="$tmpdir/${key}.a.out"
  a_err="$tmpdir/${key}.a.err"
  b_out="$tmpdir/${key}.b.out"
  b_err="$tmpdir/${key}.b.err"

  if [[ "$mode" == "ir" ]]; then
    timeout_secs="$IR_TIMEOUT_SECS"
  else
    timeout_secs="$CHECK_TIMEOUT_SECS"
  fi

  a_rc=0
  runner_exec_capture "$timeout_secs" "$a_out" "$a_err" "$COMPILER_A" "$mode" "$src" || a_rc=$?

  b_rc=0
  runner_exec_capture "$timeout_secs" "$b_out" "$b_err" "$COMPILER_B" "$mode" "$src" || b_rc=$?

  if [[ "$a_rc" -ne "$b_rc" ]]; then
    echo "FAIL(fixpoint-ir-exit-code) ${mode}|${src} stage2_rc=$a_rc stage3_rc=$b_rc"
    failures=$((failures + 1))
    continue
  fi

  if [[ "$mode" == "ir" ]]; then
    a_norm="$tmpdir/${key}.a.norm"
    b_norm="$tmpdir/${key}.b.norm"
    normalize_ir "$a_out" > "$a_norm"
    normalize_ir "$b_out" > "$b_norm"

    if ! diff -u "$a_norm" "$b_norm" > "$tmpdir/${key}.diff" 2>&1; then
      echo "FAIL(fixpoint-ir-diff) ir|${src}"
      head -20 "$tmpdir/${key}.diff" | sed 's/^/  /'
      failures=$((failures + 1))
      continue
    fi
    echo "PASS(fixpoint-ir) ir|${src}"
  else
    # check mode: compare diagnostic class
    a_diag_norm="$tmpdir/${key}.a.diag.norm"
    b_diag_norm="$tmpdir/${key}.b.diag.norm"
    normalize_check_output "$a_err" > "$a_diag_norm"
    normalize_check_output "$b_err" > "$b_diag_norm"

    if ! diff -u "$a_diag_norm" "$b_diag_norm" > "$tmpdir/${key}.diag.diff" 2>&1; then
      echo "FAIL(fixpoint-check-diff) check|${src}"
      head -10 "$tmpdir/${key}.diag.diff" | sed 's/^/  /'
      failures=$((failures + 1))
      continue
    fi
    echo "PASS(fixpoint-check) check|${src}"
  fi
done < "$CORPUS_FILE"

echo ""
echo "fixpoint IR comparison: processed=$processed failures=$failures"

if [[ "$processed" -eq 0 ]]; then
  echo "error: no ir|check entries found in corpus"
  exit 1
fi

if [[ "$failures" -ne 0 ]]; then
  echo "fixpoint IR comparison: FAIL"
  exit 1
fi

echo "fixpoint IR comparison: PASS"
