#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
source "${ROOT_DIR}/scripts/parity_states.sh"
source "${ROOT_DIR}/scripts/selfhost_runner.sh"

STAGE0_BIN="./bootstrap/zig-out/bin/with"
SELFHOST_BIN="./out/bin/with-stage2"
CORPUS_FILE="test/annoyances/async_parity_corpus.txt"

echo "building bootstrap compiler for fix_more_annoyances async parity..."
(
  cd bootstrap
  zig build -Doptimize=Debug >/dev/null
)

if [[ ! -x "$SELFHOST_BIN" ]]; then
  if [[ -x "./out/bin/with-stage1" ]]; then
    SELFHOST_BIN="./out/bin/with-stage1"
  else
    echo "rebuilding self-host compiler for fix_more_annoyances async parity..."
    ./scripts/rebuild_selfhost.sh stage2 >/dev/null
    if [[ ! -x "$SELFHOST_BIN" ]]; then
      SELFHOST_BIN="./out/bin/with-stage1"
    fi
  fi
fi

if [[ ! -x "$STAGE0_BIN" ]]; then
  echo "error: missing Stage0 compiler: $STAGE0_BIN"
  exit 1
fi
if [[ ! -x "$SELFHOST_BIN" ]]; then
  echo "error: missing self-host compiler"
  exit 1
fi
if [[ ! -f "$CORPUS_FILE" ]]; then
  echo "error: missing corpus file: $CORPUS_FILE"
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
    echo "FAIL(fix-annoyances-async-parity-missing-source) $src"
    failures=$((failures + 1))
    continue
  fi

  processed=$((processed + 1))
  key="${src//\//__}"
  stage0_err="$tmpdir/${key}.stage0.stderr"
  self_err="$tmpdir/${key}.selfhost.stderr"
  kd_line="$(parity_kd_line_for_test "$CORPUS_FILE" "$src")"

  stage0_rc=0
  "$STAGE0_BIN" check "$src" >/dev/null 2>"$stage0_err" || stage0_rc=$?
  self_rc=0
  "$SELFHOST_BIN" check "$src" >/dev/null 2>"$self_err" || self_rc=$?

  if [[ "$stage0_rc" -ne 0 || "$self_rc" -ne 0 ]]; then
    if [[ "$stage0_rc" -ne "$self_rc" ]]; then
      if [[ -n "$kd_line" ]]; then
        IFS='|' read -r _ kd_test kd_what kd_correct kd_why <<< "$kd_line"
        echo "KNOWN_DIVERGENCE(fix-annoyances-async-parity) ${kd_test} what='${kd_what}' correct='${kd_correct}' why='${kd_why}' stage0_rc=$stage0_rc selfhost_rc=$self_rc"
        echo "$kd_test" >> "$used_kd_file"
        known_divergences=$((known_divergences + 1))
      else
        echo "FAIL(fix-annoyances-async-parity-status-mismatch) $src stage0=$stage0_rc selfhost=$self_rc"
        cat "$stage0_err" || true
        cat "$self_err" || true
        failures=$((failures + 1))
      fi
      continue
    fi
    if [[ -n "$kd_line" ]]; then
      echo "FAIL(fix-annoyances-async-parity-stale-known-divergence) $src"
    else
      echo "FAIL(fix-annoyances-async-parity-both-check-failed) $src rc=$self_rc"
      cat "$stage0_err" || true
      cat "$self_err" || true
    fi
    failures=$((failures + 1))
    continue
  fi

  if [[ -n "$kd_line" ]]; then
    echo "FAIL(fix-annoyances-async-parity-stale-known-divergence) $src"
    failures=$((failures + 1))
    continue
  fi

  echo "PASS(fix-annoyances-async-parity) $src"
done < <(grep -v '^[[:space:]]*$' "$CORPUS_FILE" | sort)

if [[ "$processed" -eq 0 ]]; then
  echo "error: empty corpus: $CORPUS_FILE"
  exit 1
fi

used_known_divergences="$(sort -u "$used_kd_file" | sed '/^$/d' | wc -l | tr -d ' ')"
if [[ "$declared_known_divergences" -ne "$used_known_divergences" ]]; then
  echo "FAIL(fix-annoyances-async-parity-known-divergence-accounting) declared=$declared_known_divergences used=$used_known_divergences"
  failures=$((failures + 1))
fi

echo ""
echo "fix_more_annoyances async parity: processed=$processed failures=$failures known_divergences=$known_divergences"

if [[ "$failures" -ne 0 ]]; then
  echo "fix_more_annoyances async parity: FAIL"
  exit 1
fi

echo "fix_more_annoyances async parity: PASS"
