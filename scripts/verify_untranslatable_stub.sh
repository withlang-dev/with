#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WITH_BIN="${WITH_BIN:-$ROOT_DIR/out/bin/with}"
SRC="$ROOT_DIR/test/migrate/untranslatable_stub.c"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/with-stub-test.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

OUT="$TMP_DIR/untranslatable_stub.w"
"$WITH_BIN" migrate "$SRC" -o "$OUT" --no-c-export 2>/dev/null

# 1. File-level summary must exist
if ! grep -q '\[MIGRATOR STATUS\]' "$OUT"; then
    echo "FAIL: missing [MIGRATOR STATUS] summary" >&2
    head -10 "$OUT" >&2
    exit 1
fi

# 2. Stub marker must exist
if ! grep -q '\[MIGRATOR_UNTRANSLATED\]' "$OUT"; then
    echo "FAIL: missing [MIGRATOR_UNTRANSLATED] marker" >&2
    exit 1
fi

# 3. Source location must be present
if ! grep -q '// Source:.*untranslatable_stub\.c' "$OUT"; then
    echo "FAIL: missing Source: location" >&2
    exit 1
fi

# 4. Bail info must be present
if ! grep -q '// Bail:' "$OUT"; then
    echo "FAIL: missing Bail: line" >&2
    exit 1
fi

# 5. Original C must be included
if ! grep -q '// int untranslatable_dispatch' "$OUT"; then
    echo "FAIL: original C source not included" >&2
    exit 1
fi

if ! grep -q '&&L_ADD' "$OUT"; then
    echo "FAIL: computed goto source not in original C comment" >&2
    exit 1
fi

# 6. comptime_error stub must exist
if ! grep -q "comptime_error.*untranslatable function 'untranslatable_dispatch'" "$OUT"; then
    echo "FAIL: comptime_error stub missing" >&2
    exit 1
fi

# 7. Translatable function must still work
if ! grep -q 'fn translatable_add' "$OUT"; then
    echo "FAIL: translatable function missing from output" >&2
    exit 1
fi

echo "VERIFIED: untranslatable stub output contains marker, source, bail info, and original C"
