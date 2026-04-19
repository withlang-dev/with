#!/usr/bin/env bash
# pcre2_migrate_bench.sh — Run the PCRE2 C-to-With migration with fixed
# flags and print a reproducible summary.
#
# Usage: ./scripts/pcre2_migrate_bench.sh
# Must be run from the repo root.

set -euo pipefail

# --- Configuration (canonical, do not change between runs) ---------------

PCRE2_SRC=".reference/pcre2/src"
WITH="./out/bin/with"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTDIR="/tmp/pcre2_bench_${TIMESTAMP}"
LOGFILE="${OUTDIR}/migrate.log"

DEFINES=(
    -D PCRE2_CODE_UNIT_WIDTH=8
    -D HAVE_CONFIG_H
    -D LINK_SIZE=2
    -D MATCH_LIMIT=10000000
    -D MATCH_LIMIT_DEPTH=10000000
    -D NEWLINE_DEFAULT=2
    -D PARENS_NEST_LIMIT=250
    -D MAX_NAME_COUNT=10000
    -D MAX_NAME_SIZE=32
    -D MAX_VARLOOKBEHIND=255
    -D HEAP_LIMIT=20000000
)

EXCLUDES=(
    --exclude pcre2test.c
    --exclude pcre2_jit_compile.c
    --exclude pcre2_jit_match.c
    --exclude pcre2_jit_misc.c
    --exclude pcre2_fuzzsupport.c
    --exclude pcre2grep.c
    --exclude pcre2_ucptables_inc.h
    --exclude pcre2_printint.c
    --exclude pcre2posix_test.c
)

# --- Preflight checks ----------------------------------------------------

if [ ! -d "$PCRE2_SRC" ]; then
    echo "error: PCRE2 source not found at $PCRE2_SRC" >&2
    echo "       Run: ./scripts/prepare_pcre2_reference.sh" >&2
    exit 1
fi

if [ ! -x "$WITH" ]; then
    echo "error: migrator not found at $WITH" >&2
    echo "       Run: make build" >&2
    exit 1
fi

# --- Run migration -------------------------------------------------------

rm -rf "$OUTDIR"
mkdir -p "$OUTDIR"

echo "PCRE2 migration benchmark"
echo "  output:  $OUTDIR"
echo "  migrator: $WITH"
echo ""

START_NS=$(python3 -c "import time; print(int(time.time()*1e9))")

# Migration returns non-zero when there are untranslatable functions;
# capture the exit code but don't abort.
set +e
"$WITH" migrate "$PCRE2_SRC/" -o "$OUTDIR/" \
    --no-c-export \
    -I "$PCRE2_SRC" \
    "${DEFINES[@]}" \
    "${EXCLUDES[@]}" \
    2>"$LOGFILE"
EXIT_CODE=$?
set -e

END_NS=$(python3 -c "import time; print(int(time.time()*1e9))")
ELAPSED_MS=$(( (END_NS - START_NS) / 1000000 ))

# --- Parse results from stderr log ---------------------------------------

# Summary line format (last "migrate:" line with "functions translated"):
#   migrate: 30/30 files, 280/310 functions translated, 30 untranslatable
# or (all clean):
#   migrate: 30/30 files, 310 functions translated from ...
SUMMARY_LINE=$(grep -E "^migrate:.*functions translated" "$LOGFILE" | tail -1 || true)

if [ -z "$SUMMARY_LINE" ]; then
    echo "error: no summary line found in migration output" >&2
    echo "       log: $LOGFILE" >&2
    exit 1
fi

# Extract counts from the summary line.
FILES_MIGRATED=$(echo "$SUMMARY_LINE" | grep -oE '[0-9]+/[0-9]+ files' | head -1 || true)
TRANSLATED=$(echo "$SUMMARY_LINE" | grep -oE '[0-9]+/[0-9]+ functions' | head -1 || true)
UNTRANSLATABLE=$(echo "$SUMMARY_LINE" | grep -oE '[0-9]+ untranslatable' | grep -oE '[0-9]+' || echo "0")

# Count output .w files
OUTPUT_FILES=$(find "$OUTDIR" -name '*.w' | wc -l | tr -d ' ')

# Collect untranslatable function details from per-file lines.
# Format: migrate: untranslatable function 'name': bailed at KIND (location)
# or:     migrate: untranslatable function 'name': body translation failed
# or:     migrate: untranslatable function 'name': unsupported type (reason)
UNTRANS_LINES=$(grep "untranslatable function" "$LOGFILE" || true)

# --- Git info for reproducibility ----------------------------------------

GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_DIRTY=$(git diff --quiet 2>/dev/null && echo "" || echo " (dirty)")

# --- Print summary -------------------------------------------------------

echo "========================================"
echo "  PCRE2 Migration Benchmark Summary"
echo "========================================"
echo ""
echo "Date:       $(date '+%Y-%m-%d %H:%M:%S')"
echo "Commit:     ${GIT_COMMIT}${GIT_DIRTY}"
echo "Elapsed:    ${ELAPSED_MS}ms"
echo "Exit code:  ${EXIT_CODE}"
echo ""
echo "Files:      ${FILES_MIGRATED}"
echo "Output:     ${OUTPUT_FILES} .w files in ${OUTDIR}"
echo "Functions:  ${TRANSLATED}"
echo "Untrans:    ${UNTRANSLATABLE}"
echo ""

if [ -n "$UNTRANS_LINES" ]; then
    UNTRANS_COUNT=$(echo "$UNTRANS_LINES" | wc -l | tr -d ' ')
    echo "--- Untranslatable functions (${UNTRANS_COUNT}) ---"
    echo ""
    echo "$UNTRANS_LINES" | sed 's/^migrate: /  /'
    echo ""
fi

echo "Full log:   ${LOGFILE}"
echo "========================================"
