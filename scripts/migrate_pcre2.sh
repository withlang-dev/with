#!/bin/bash
# Migrate PCRE2 from C to With, apply patches, deploy to lib/std/re/.
#
# Prerequisites:
#   - .reference/pcre2/ must contain PCRE2 source
#   - .reference/pcre2/src/pcre2.h generated from pcre2.h.generic
#   - .reference/pcre2/src/config.h prepared for the 8-bit build
#   - .reference/pcre2/src/pcre2_chartables.c from pcre2_chartables.c.dist
#   - out/bin/with must be built
#
# Usage: ./scripts/migrate_pcre2.sh

set -euo pipefail

PCRE2_SRC=".reference/pcre2/src"
MIGRATE_OUT="out/pcre2_migrate"
LIB_RE="lib/std/re"
PATCH="scripts/pcre2_migrate.patch"
WITH="./out/bin/with"

echo "=== Step 1: Ensure PCRE2 headers are set up ==="
bash "./scripts/prepare_pcre2_reference.sh" "$PCRE2_SRC"

echo "=== Step 2: Run with migrate ==="
rm -rf "$MIGRATE_OUT" && mkdir -p "$MIGRATE_OUT"
$WITH migrate "$PCRE2_SRC/" -o "$MIGRATE_OUT/" \
    -I "$PCRE2_SRC" \
    -D PCRE2_CODE_UNIT_WIDTH=8 \
    -D HAVE_CONFIG_H=1

echo "=== Step 3: Deploy to lib/std/re/ ==="
rm -rf "$LIB_RE" && mkdir -p "$LIB_RE"

# Copy only library core files (exclude test/demo/grep/jit/tools)
for f in "$MIGRATE_OUT"/*.w; do
    base=$(basename "$f")
    case "$base" in
        pcre2test.w|pcre2demo.w|pcre2grep.w|pcre2posix_test.w|\
        pcre2_jit_test.w|pcre2_jit_compile.w|pcre2_dftables.w|\
        pcre2_fuzzsupport.w)
            ;;
        *)
            cp "$f" "$LIB_RE/"
            ;;
    esac
done

echo "=== Step 4: Extract shared preamble ==="
PREAMBLE_END=$(grep -n "type BOOL\|type PCRE2_UCHAR8" "$LIB_RE/pcre2_tables.w" | head -1 | cut -d: -f1)
PREAMBLE_END=$((PREAMBLE_END - 1))
head -"$PREAMBLE_END" "$LIB_RE/pcre2_tables.w" > "$LIB_RE/defs.w"
sed -i '' '1s|.*|// std.re.defs — shared type aliases for migrated PCRE2|' "$LIB_RE/defs.w"

# Strip preamble from all files, add use std.re.defs
for f in "$LIB_RE"/*.w; do
    [ "$(basename "$f")" = "defs.w" ] && continue
    line=$(grep -n "type BOOL\|type PCRE2_UCHAR8" "$f" 2>/dev/null | head -1 | cut -d: -f1)
    [ -z "$line" ] && continue
    tail -n +"$line" "$f" > /tmp/pcre2_body.tmp
    printf "// Migrated from PCRE2\nuse std.re.defs\n\n" > "$f"
    cat /tmp/pcre2_body.tmp >> "$f"
done
rm -f /tmp/pcre2_body.tmp

# Remove 16/32-bit type aliases (we build 8-bit only)
for f in "$LIB_RE"/*.w; do
    grep -v 'pcre2_.*_16\b\|pcre2_.*_32\b\|PCRE2_UCHAR16\|PCRE2_UCHAR32\|PCRE2_SPTR16\|PCRE2_SPTR32' "$f" > /tmp/pcre2_clean.tmp
    mv /tmp/pcre2_clean.tmp "$f"
done

# Replace NULL pattern
sed -i '' 's/((0 as \*mut c_void))/null/g' "$LIB_RE"/*.w

echo "=== Step 5: Apply patches ==="
if [ -f "$PATCH" ]; then
    # Patch was generated with: diff -ruN lib/std/re/ lib/std/re.patched/
    # Apply from project root, stripping the lib/std/re/ prefix
    patch -d "$LIB_RE" -p1 --no-backup-if-mismatch < "$PATCH" || echo "  WARNING: Some patches failed (may need updating)"
    echo "  Applied $(grep -c '^diff' "$PATCH") patches"
else
    echo "  No patch file found at $PATCH"
fi

echo "=== Step 6: Count errors ==="
TOTAL=0; OK=0
for mod in $(ls "$LIB_RE"/*.w | sed "s|$LIB_RE/||;s|\.w||" | sort); do
    head -48 "$MIGRATE_OUT/pcre2_tables.w" > /tmp/tf.w
    tail -n +3 "$LIB_RE/$mod.w" >> /tmp/tf.w
    echo -e "\nfn main: print(\"ok\")" >> /tmp/tf.w
    errs=$($WITH check /tmp/tf.w 2>&1 | grep -c "error:" || true)
    TOTAL=$((TOTAL + errs))
    if [ "$errs" -eq 0 ]; then OK=$((OK + 1)); fi
done
rm -f /tmp/tf.w

echo ""
echo "=== Result: OK=$OK modules, $TOTAL errors ==="
