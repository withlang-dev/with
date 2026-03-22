#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
source "${ROOT_DIR}/scripts/parity_states.sh"
source "${ROOT_DIR}/scripts/selfhost_runner.sh"

# selfhost seed checkpoint
STAGE0_BIN="${ROOT_DIR:-./}/src/main"
SELFHOST_BIN="./out/bin/with-stage2"
CORPUS_FILE="test/wave3/ast_corpus.txt"
VERIFY_COVERAGE_SCRIPT="scripts/verify_wave3_coverage.sh"
CHECK_TIMEOUT_SECS="${PARITY_CHECK_TIMEOUT_SECS:-60}"

echo "rebuilding self-host compiler for Wave 3 AST parity..."
make stage2 >/dev/null

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
  echo "error: missing Wave 3 coverage verifier: $VERIFY_COVERAGE_SCRIPT"
  exit 1
fi
if ! "$VERIFY_COVERAGE_SCRIPT"; then
  exit 1
fi
if ! parity_validate_known_divergences "$CORPUS_FILE"; then
  exit 1
fi

SELFHOST_BIN="$(prepare_selfhost_runner "$ROOT_DIR" "$SELFHOST_BIN")"

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
    echo "FAIL(wave3-ast-parity-missing-source) $src"
    failures=$((failures + 1))
    continue
  fi

  processed=$((processed + 1))
  key="${src//\//__}"
  stage0_out="$tmpdir/${key}.stage0.ast"
  self_out_1="$tmpdir/${key}.selfhost.ast.1"
  self_out_2="$tmpdir/${key}.selfhost.ast.2"
  kd_line="$(parity_kd_line_for_test "$CORPUS_FILE" "$src")"

  stage0_rc=0
  runner_exec_capture "$CHECK_TIMEOUT_SECS" "$stage0_out" "$tmpdir/${key}.stage0.stderr" "$STAGE0_BIN" check "$src" --dump-ast || stage0_rc=$?
  self_rc_1=0
  runner_exec_capture "$CHECK_TIMEOUT_SECS" "$self_out_1" "$tmpdir/${key}.selfhost.stderr" "$SELFHOST_BIN" check "$src" --dump-ast || self_rc_1=$?

  if [[ "$stage0_rc" -ne 0 || "$self_rc_1" -ne 0 ]]; then
    if [[ "$stage0_rc" -ne "$self_rc_1" ]]; then
      if [[ -n "$kd_line" ]]; then
        IFS='|' read -r _ kd_test kd_what kd_correct kd_why <<< "$kd_line"
        echo "KNOWN_DIVERGENCE(wave3-ast-parity) ${kd_test} what='${kd_what}' correct='${kd_correct}' why='${kd_why}' stage0_rc=$stage0_rc selfhost_rc=$self_rc_1"
        echo "$kd_test" >> "$used_kd_file"
        known_divergences=$((known_divergences + 1))
      else
        echo "FAIL(wave3-ast-parity-status-mismatch) $src stage0=$stage0_rc selfhost=$self_rc_1"
        cat "$tmpdir/${key}.stage0.stderr" || true
        cat "$tmpdir/${key}.selfhost.stderr" || true
        failures=$((failures + 1))
      fi
      continue
    fi
    if [[ -n "$kd_line" ]]; then
      echo "FAIL(wave3-ast-parity-stale-known-divergence) $src"
    else
      echo "FAIL(wave3-ast-parity-both-check-failed) $src rc=$self_rc_1"
      cat "$tmpdir/${key}.stage0.stderr" || true
      cat "$tmpdir/${key}.selfhost.stderr" || true
    fi
    failures=$((failures + 1))
    continue
  fi

  if ! head -n 1 "$self_out_1" | grep -Eq '^module span=[0-9]+\.\.[0-9]+ decls=[0-9]+$'; then
    echo "FAIL(wave3-ast-format-header) $src"
    head -n 3 "$self_out_1" || true
    failures=$((failures + 1))
    continue
  fi
  if ! grep -q '^---$' "$self_out_1"; then
    echo "FAIL(wave3-ast-format-separator) $src"
    failures=$((failures + 1))
    continue
  fi

  if ! runner_exec_capture "$CHECK_TIMEOUT_SECS" "$self_out_2" "$tmpdir/${key}.selfhost.stderr.2" "$SELFHOST_BIN" check "$src" --dump-ast; then
    echo "FAIL(wave3-ast-parity-selfhost-recheck) $src"
    cat "$tmpdir/${key}.selfhost.stderr.2"
    failures=$((failures + 1))
    continue
  fi

  if ! diff -u "$self_out_1" "$self_out_2" >/dev/null; then
    echo "FAIL(wave3-ast-parity-nondeterministic-selfhost) $src"
    diff -u "$self_out_1" "$self_out_2" || true
    failures=$((failures + 1))
    continue
  fi

  if diff -u "$stage0_out" "$self_out_1" >/dev/null; then
    if [[ -n "$kd_line" ]]; then
      echo "FAIL(wave3-ast-parity-stale-known-divergence) $src"
      failures=$((failures + 1))
      continue
    fi
    echo "PASS(wave3-ast-parity) $src"
  else
    if [[ -n "$kd_line" ]]; then
      IFS='|' read -r _ kd_test kd_what kd_correct kd_why <<< "$kd_line"
      echo "KNOWN_DIVERGENCE(wave3-ast-parity) ${kd_test} what='${kd_what}' correct='${kd_correct}' why='${kd_why}'"
      echo "$kd_test" >> "$used_kd_file"
      known_divergences=$((known_divergences + 1))
    else
      echo "FAIL(wave3-ast-parity-diff) $src"
      diff -u "$stage0_out" "$self_out_1" || true
      failures=$((failures + 1))
    fi
  fi
done < <(grep -v '^[[:space:]]*$' "$CORPUS_FILE" | sort)

if [[ "$processed" -eq 0 ]]; then
  echo "error: empty corpus: $CORPUS_FILE"
  exit 1
fi
used_known_divergences="$(sort -u "$used_kd_file" | sed '/^$/d' | wc -l | tr -d ' ')"
if [[ "$declared_known_divergences" -ne "$used_known_divergences" ]]; then
  echo "FAIL(wave3-ast-parity-known-divergence-accounting) declared=$declared_known_divergences used=$used_known_divergences"
  failures=$((failures + 1))
fi

echo ""
echo "wave3 AST parity: processed=$processed failures=$failures known_divergences=$known_divergences"

if [[ "$failures" -ne 0 ]]; then
  echo "wave3 AST parity: FAIL"
  exit 1
fi

echo "wave3 AST parity: PASS"
