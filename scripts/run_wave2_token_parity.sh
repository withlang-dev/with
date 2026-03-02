#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

STAGE0_BIN="./bootstrap/zig-out/bin/with"
SELFHOST_BIN="./with-stage2"
CORPUS_FILE="test/wave2/token_corpus.txt"

echo "building bootstrap compiler for Wave 2 token parity..."
(
  cd bootstrap
  zig build -Doptimize=Debug >/dev/null
)

echo "rebuilding self-host compiler for Wave 2 token parity..."
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
    echo "FAIL(wave2-token-parity-missing-source) $src"
    failures=$((failures + 1))
    continue
  fi

  processed=$((processed + 1))
  key="${src//\//__}"
  stage0_out="$tmpdir/${key}.stage0.tokens"
  self_out_1="$tmpdir/${key}.selfhost.tokens.1"
  self_out_2="$tmpdir/${key}.selfhost.tokens.2"

  if ! "$STAGE0_BIN" check "$src" --dump-tokens >"$stage0_out" 2>"$tmpdir/${key}.stage0.stderr"; then
    echo "FAIL(wave2-token-parity-stage0-check) $src"
    cat "$tmpdir/${key}.stage0.stderr"
    failures=$((failures + 1))
    continue
  fi

  if ! "$SELFHOST_BIN" check "$src" --dump-tokens >"$self_out_1" 2>"$tmpdir/${key}.selfhost.stderr"; then
    echo "FAIL(wave2-token-parity-selfhost-check) $src"
    cat "$tmpdir/${key}.selfhost.stderr"
    failures=$((failures + 1))
    continue
  fi

  if ! "$SELFHOST_BIN" check "$src" --dump-tokens >"$self_out_2" 2>"$tmpdir/${key}.selfhost.stderr.2"; then
    echo "FAIL(wave2-token-parity-selfhost-recheck) $src"
    cat "$tmpdir/${key}.selfhost.stderr.2"
    failures=$((failures + 1))
    continue
  fi

  if ! diff -u "$self_out_1" "$self_out_2" >/dev/null; then
    echo "FAIL(wave2-token-parity-nondeterministic-selfhost) $src"
    diff -u "$self_out_1" "$self_out_2" || true
    failures=$((failures + 1))
    continue
  fi

  if diff -u "$stage0_out" "$self_out_1" >/dev/null; then
    echo "PASS(wave2-token-parity) $src"
  else
    echo "FAIL(wave2-token-parity-diff) $src"
    diff -u "$stage0_out" "$self_out_1" || true
    failures=$((failures + 1))
  fi
done < <(grep -v '^[[:space:]]*$' "$CORPUS_FILE" | sort)

if [[ "$processed" -eq 0 ]]; then
  echo "error: empty corpus: $CORPUS_FILE"
  exit 1
fi

if [[ "$failures" -ne 0 ]]; then
  echo "wave2 token parity: $failures failure(s)"
  exit 1
fi

echo "wave2 token parity: PASS"
