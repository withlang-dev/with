#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

STAGE0_BIN="./bootstrap/zig-out/bin/with"
SELFHOST_BIN="./with-stage2"
CORPUS_FILE="test/wave4/resolved_corpus.txt"

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

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0
processed=0

while IFS= read -r src; do
  [[ -z "$src" ]] && continue
  [[ "${src:0:1}" == "#" ]] && continue

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
  "$STAGE0_BIN" check "$src" > /dev/null 2>"$stage0_stderr" || stage0_rc=$?
  self_rc=0
  "$SELFHOST_BIN" check "$src" > /dev/null 2>"$self_stderr" || self_rc=$?

  if [[ "$stage0_rc" -ne "$self_rc" ]]; then
    echo "FAIL(wave4-resolved-parity-status-mismatch) $src stage0=$stage0_rc selfhost=$self_rc"
    cat "$stage0_stderr" || true
    cat "$self_stderr" || true
    failures=$((failures + 1))
    continue
  fi

  if ! "$SELFHOST_BIN" check "$src" --dump-resolved >"$self_out_1" 2>"$tmpdir/${key}.self.resolved.stderr.1"; then
    echo "FAIL(wave4-resolved-parity-selfhost-dump) $src"
    cat "$tmpdir/${key}.self.resolved.stderr.1"
    failures=$((failures + 1))
    continue
  fi

  if ! "$SELFHOST_BIN" check "$src" --dump-resolved >"$self_out_2" 2>"$tmpdir/${key}.self.resolved.stderr.2"; then
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

if [[ "$failures" -ne 0 ]]; then
  echo "wave4 resolved parity: $failures failure(s)"
  exit 1
fi

echo "wave4 resolved parity: PASS"
