#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
GOLDEN_DIR="test/golden/wave0"
CORPUS_FILE="$GOLDEN_DIR/corpus.txt"

update_mode=0
if [[ "${1:-}" == "--update" ]]; then
  update_mode=1
fi

echo "building compiler binary for phase0 golden dump tests..."
zig build -Doptimize=Debug >/dev/null

if [[ ! -f "$CORPUS_FILE" ]]; then
  echo "FAIL(phase0-golden-corpus-missing) $CORPUS_FILE"
  exit 1
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0
processed=0

dump_and_compare() {
  local src="$1"
  local key="$2"
  local dump_flag="$3"
  local suffix="$4"

  local out_file="$tmpdir/${key}.${suffix}.tmp"
  local out_file_second="$tmpdir/${key}.${suffix}.tmp.2"
  local golden_file="$GOLDEN_DIR/${key}.${suffix}.golden"

  if ! "$WITH_BIN" check "$src" "$dump_flag" >"$out_file" 2>"$tmpdir/stderr.log"; then
    echo "FAIL(phase0-golden-dump) $src $dump_flag"
    cat "$tmpdir/stderr.log"
    failures=$((failures + 1))
    return
  fi
  if ! "$WITH_BIN" check "$src" "$dump_flag" >"$out_file_second" 2>"$tmpdir/stderr.log"; then
    echo "FAIL(phase0-golden-repeat-dump) $src $dump_flag"
    cat "$tmpdir/stderr.log"
    failures=$((failures + 1))
    return
  fi
  if ! diff -u "$out_file" "$out_file_second" >/dev/null; then
    echo "FAIL(phase0-golden-nondeterministic) $src $suffix"
    diff -u "$out_file" "$out_file_second" || true
    failures=$((failures + 1))
    return
  fi

  if [[ "$update_mode" -eq 1 ]]; then
    cp "$out_file" "$golden_file"
    echo "PASS(phase0-golden-update) $src $suffix"
    return
  fi

  if [[ ! -f "$golden_file" ]]; then
    echo "FAIL(phase0-golden-missing) $golden_file"
    failures=$((failures + 1))
    return
  fi

  if diff -u "$golden_file" "$out_file" >/dev/null; then
    echo "PASS(phase0-golden-verify) $src $suffix"
  else
    echo "FAIL(phase0-golden-diff) $src $suffix"
    diff -u "$golden_file" "$out_file" || true
    failures=$((failures + 1))
  fi
}

while IFS= read -r src; do
  [[ -z "$src" ]] && continue
  [[ "${src:0:1}" == "#" ]] && continue

  if [[ ! -f "$src" ]]; then
    echo "FAIL(phase0-golden-missing-source) $src"
    failures=$((failures + 1))
    continue
  fi

  processed=$((processed + 1))
  key="${src%.w}"
  key="${key//\//__}"

  dump_and_compare "$src" "$key" "--dump-tokens" "tokens"
  dump_and_compare "$src" "$key" "--dump-ast" "ast"
  dump_and_compare "$src" "$key" "--dump-typed" "typed"
  dump_and_compare "$src" "$key" "--dump-llvm-ir" "llvm"
done < <(grep -v '^[[:space:]]*$' "$CORPUS_FILE" | sort)

if [[ "$processed" -eq 0 ]]; then
  echo "FAIL(phase0-golden-empty-corpus) $CORPUS_FILE"
  exit 1
fi

if [[ "$failures" -ne 0 ]]; then
  echo "phase0 golden dump tests: $failures failure(s)"
  exit 1
fi

echo "phase0 golden dump tests: PASS"
