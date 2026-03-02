#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

STAGE0_BIN="./bootstrap/zig-out/bin/with"
SELFHOST_BIN="./with-stage2"
CORPUS_FILE="test/wave3/ast_corpus.txt"

echo "building bootstrap compiler for Wave 3 AST parity..."
(
  cd bootstrap
  zig build -Doptimize=Debug >/dev/null
)

echo "rebuilding self-host compiler for Wave 3 AST parity..."
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
    echo "FAIL(wave3-ast-parity-missing-source) $src"
    failures=$((failures + 1))
    continue
  fi

  processed=$((processed + 1))
  key="${src//\//__}"
  stage0_out="$tmpdir/${key}.stage0.ast"
  self_out_1="$tmpdir/${key}.selfhost.ast.1"
  self_out_2="$tmpdir/${key}.selfhost.ast.2"

  if ! "$STAGE0_BIN" check "$src" --dump-ast >"$stage0_out" 2>"$tmpdir/${key}.stage0.stderr"; then
    echo "FAIL(wave3-ast-parity-stage0-check) $src"
    cat "$tmpdir/${key}.stage0.stderr"
    failures=$((failures + 1))
    continue
  fi

  if ! "$SELFHOST_BIN" check "$src" --dump-ast >"$self_out_1" 2>"$tmpdir/${key}.selfhost.stderr"; then
    echo "FAIL(wave3-ast-parity-selfhost-check) $src"
    cat "$tmpdir/${key}.selfhost.stderr"
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

  if ! "$SELFHOST_BIN" check "$src" --dump-ast >"$self_out_2" 2>"$tmpdir/${key}.selfhost.stderr.2"; then
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
    echo "PASS(wave3-ast-parity) $src"
  else
    echo "FAIL(wave3-ast-parity-diff) $src"
    diff -u "$stage0_out" "$self_out_1" || true
    failures=$((failures + 1))
  fi
done < <(grep -v '^[[:space:]]*$' "$CORPUS_FILE" | sort)

if [[ "$processed" -eq 0 ]]; then
  echo "error: empty corpus: $CORPUS_FILE"
  exit 1
fi

if [[ "$failures" -ne 0 ]]; then
  echo "wave3 AST parity: $failures failure(s)"
  exit 1
fi

echo "wave3 AST parity: PASS"
