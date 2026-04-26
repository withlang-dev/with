#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WITH_BIN="${WITH_BIN:-$ROOT_DIR/out/bin/with}"
SRC="$ROOT_DIR/test/migrate/untranslatable_stub.c"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/with-stub-test.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

OUT="$TMP_DIR/untranslatable_stub.w"
if "$WITH_BIN" migrate "$SRC" -o "$OUT" --no-c-export 2>"$TMP_DIR/err"; then
    echo "FAIL: computed goto migration unexpectedly succeeded" >&2
    sed -n '1,120p' "$OUT" >&2 || true
    exit 1
fi

if ! grep -q "computed goto is not supported" "$TMP_DIR/err"; then
    echo "FAIL: missing computed-goto diagnostic" >&2
    cat "$TMP_DIR/err" >&2
    exit 1
fi

if [[ -e "$OUT" ]] && grep -q "comptime_error.*untranslatable function 'untranslatable_dispatch'" "$OUT"; then
    echo "FAIL: computed goto emitted a comptime_error stub" >&2
    sed -n '1,120p' "$OUT" >&2
    exit 1
fi

echo "VERIFIED: computed goto fails loudly without emitting a stub"
