#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
source "${ROOT_DIR}/scripts/parity_states.sh"
source "${ROOT_DIR}/scripts/selfhost_runner.sh"

STAGE0_BIN="./bootstrap/zig-out/bin/with"
SELFHOST_BIN="./with-stage2"
CORPUS_FILE="test/wave4/resolved_corpus.txt"
VERIFY_COVERAGE_SCRIPT="scripts/verify_wave4_coverage.sh"
CHECK_TIMEOUT_SECS="${PARITY_CHECK_TIMEOUT_SECS:-60}"

echo "building bootstrap compiler for Wave 4 resolved parity..."
(
  cd bootstrap
  zig build -Doptimize=Debug >/dev/null
)

echo "rebuilding self-host compiler for Wave 4 resolved parity..."
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
  echo "error: missing Wave 4 coverage verifier: $VERIFY_COVERAGE_SCRIPT"
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
    echo "FAIL(wave4-resolved-parity-missing-source) $src"
    failures=$((failures + 1))
    continue
  fi

  processed=$((processed + 1))
  key="${src//\//__}"
  stage0_stderr="$tmpdir/${key}.stage0.stderr"
  self_stderr="$tmpdir/${key}.self.stderr"
  self_out_1="$tmpdir/${key}.self.resolved.1"
  self_out_2="$tmpdir/${key}.self.resolved.2"

  stage0_rc=0
  runner_exec_capture "$CHECK_TIMEOUT_SECS" /dev/null "$stage0_stderr" "$STAGE0_BIN" check "$src" || stage0_rc=$?
  self_rc=0
  runner_exec_capture "$CHECK_TIMEOUT_SECS" /dev/null "$self_stderr" "$SELFHOST_BIN" check "$src" || self_rc=$?
  kd_line="$(parity_kd_line_for_test "$CORPUS_FILE" "$src")"

  if [[ "$stage0_rc" -ne "$self_rc" ]]; then
    if [[ -n "$kd_line" ]]; then
      IFS='|' read -r _ kd_test kd_what kd_correct kd_why <<< "$kd_line"
      echo "KNOWN_DIVERGENCE(wave4-resolved-parity) ${kd_test} what='${kd_what}' correct='${kd_correct}' why='${kd_why}' stage0=$stage0_rc selfhost=$self_rc"
      echo "$kd_test" >> "$used_kd_file"
      known_divergences=$((known_divergences + 1))
    else
      echo "FAIL(wave4-resolved-parity-status-mismatch) $src stage0=$stage0_rc selfhost=$self_rc"
      cat "$stage0_stderr" || true
      cat "$self_stderr" || true
      failures=$((failures + 1))
    fi
    continue
  fi

  if [[ -n "$kd_line" ]]; then
    echo "FAIL(wave4-resolved-parity-stale-known-divergence) $src"
    failures=$((failures + 1))
    continue
  fi

  # Both compilers agree on non-zero exit → error case parity PASS.
  if [[ "$stage0_rc" -ne 0 && "$self_rc" -ne 0 ]]; then
    echo "PASS(wave4-resolved-parity) $src"
    continue
  fi

  if ! runner_exec_capture "$CHECK_TIMEOUT_SECS" "$self_out_1" "$tmpdir/${key}.self.resolved.stderr.1" "$SELFHOST_BIN" check "$src" --dump-resolved; then
    echo "FAIL(wave4-resolved-parity-selfhost-dump) $src"
    cat "$tmpdir/${key}.self.resolved.stderr.1"
    failures=$((failures + 1))
    continue
  fi

  if ! runner_exec_capture "$CHECK_TIMEOUT_SECS" "$self_out_2" "$tmpdir/${key}.self.resolved.stderr.2" "$SELFHOST_BIN" check "$src" --dump-resolved; then
    echo "FAIL(wave4-resolved-parity-selfhost-redump) $src"
    cat "$tmpdir/${key}.self.resolved.stderr.2"
    failures=$((failures + 1))
    continue
  fi

  if ! diff -u "$self_out_1" "$self_out_2" >/dev/null; then
    echo "FAIL(wave4-resolved-parity-nondeterministic-selfhost) $src"
    diff -u "$self_out_1" "$self_out_2" || true
    failures=$((failures + 1))
    continue
  fi

  if ! head -n 1 "$self_out_1" | grep -Eq '^resolved root=.* modules=[0-9]+ defs=[0-9]+$'; then
    echo "FAIL(wave4-resolved-parity-format-header) $src"
    head -n 3 "$self_out_1" || true
    failures=$((failures + 1))
    continue
  fi
  if ! grep -q '^module\[0\] ' "$self_out_1"; then
    echo "FAIL(wave4-resolved-parity-format-root-module) $src"
    failures=$((failures + 1))
    continue
  fi

  echo "PASS(wave4-resolved-parity) $src"
done < <(grep -v '^[[:space:]]*$' "$CORPUS_FILE" | sort)

if [[ "$processed" -eq 0 ]]; then
  echo "error: empty corpus: $CORPUS_FILE"
  exit 1
fi
used_known_divergences="$(sort -u "$used_kd_file" | sed '/^$/d' | wc -l | tr -d ' ')"
if [[ "$declared_known_divergences" -ne "$used_known_divergences" ]]; then
  echo "FAIL(wave4-resolved-parity-known-divergence-accounting) declared=$declared_known_divergences used=$used_known_divergences"
  failures=$((failures + 1))
fi

echo ""
echo "wave4 resolved parity: processed=$processed failures=$failures known_divergences=$known_divergences"

if [[ "$failures" -ne 0 ]]; then
  echo "wave4 resolved parity: FAIL"
  exit 1
fi

echo "wave4 resolved parity: PASS"
