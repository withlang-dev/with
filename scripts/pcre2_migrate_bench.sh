#!/usr/bin/env bash
# pcre2_migrate_bench.sh — Three-gate PCRE2 migration benchmark.
#
#   Gate 1 (migrate):  Translate C → With via the migrator.
#   Gate 2 (compile):  Type-check the migrated .w files.
#   Gate 3 (match):    Link migrated code, run pcre2test on testinput1.
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

# --- Setup ---------------------------------------------------------------

rm -rf "$OUTDIR"
mkdir -p "$OUTDIR"

GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_DIRTY=$(git diff --quiet 2>/dev/null && echo "" || echo " (dirty)")

OVERALL_EXIT=0

echo "========================================"
echo "  PCRE2 Three-Gate Benchmark"
echo "========================================"
echo ""
echo "Date:    $(date '+%Y-%m-%d %H:%M:%S')"
echo "Commit:  ${GIT_COMMIT}${GIT_DIRTY}"
echo "Output:  $OUTDIR"
echo ""

# =========================================================================
# Gate 1: Migration
# =========================================================================

echo "--- Gate 1: migrate ---"
echo ""

GATE1_START=$(python3 -c "import time; print(int(time.time()*1e9))")

set +e
"$WITH" migrate "$PCRE2_SRC/" -o "$OUTDIR/" \
    --no-c-export \
    --width-slice 8 \
    -I "$PCRE2_SRC" \
    "${DEFINES[@]}" \
    "${EXCLUDES[@]}" \
    2>"$LOGFILE"
MIGRATE_EXIT=$?
set -e

GATE1_END=$(python3 -c "import time; print(int(time.time()*1e9))")
GATE1_MS=$(( (GATE1_END - GATE1_START) / 1000000 ))

SUMMARY_LINE=$(grep -E "^migrate:.*functions translated" "$LOGFILE" | tail -1 || true)

if [ -z "$SUMMARY_LINE" ]; then
    echo "migrate: FAIL (no summary line in log)"
    echo "         log: $LOGFILE"
    OVERALL_EXIT=1
    echo ""
    echo "Full log: $LOGFILE"
    echo "========================================"
    exit $OVERALL_EXIT
fi

FILES_MIGRATED=$(echo "$SUMMARY_LINE" | grep -oE '[0-9]+/[0-9]+ files' | head -1 || true)
TRANSLATED=$(echo "$SUMMARY_LINE" | grep -oE '[0-9]+(/[0-9]+)? functions' | head -1 || true)
UNTRANSLATABLE=$(echo "$SUMMARY_LINE" | grep -oE '[0-9]+ untranslatable' | grep -oE '[0-9]+' || echo "0")
OUTPUT_FILES=$(find "$OUTDIR" -name '*.w' | wc -l | tr -d ' ')

if [ "$UNTRANSLATABLE" = "0" ]; then
    echo "migrate: PASS ($TRANSLATED, $FILES_MIGRATED, ${GATE1_MS}ms)"
    GATE1_PASS=true
else
    echo "migrate: FAIL ($TRANSLATED, $UNTRANSLATABLE untranslatable)"
    GATE1_PASS=true  # proceed to gate 2 even with untranslatable functions
    UNTRANS_LINES=$(grep "untranslatable function" "$LOGFILE" || true)
    if [ -n "$UNTRANS_LINES" ]; then
        echo ""
        echo "$UNTRANS_LINES" | head -10 | sed 's/^migrate: /  /'
        UNTRANS_TOTAL=$(echo "$UNTRANS_LINES" | wc -l | tr -d ' ')
        if [ "$UNTRANS_TOTAL" -gt 10 ]; then
            echo "  ... and $((UNTRANS_TOTAL - 10)) more"
        fi
    fi
fi

echo ""

# =========================================================================
# Gate 2: Compile (type-check migrated .w files)
# =========================================================================

echo "--- Gate 2: compile ---"
echo ""

GATE2_LOG="$OUTDIR/compile.log"
GATE2_ERRORS=0
GATE2_PASS_COUNT=0
GATE2_FAIL_COUNT=0
GATE2_FAIL_FILES=""
GATE2_FIRST_ERRORS=""

# Stage migrated files into lib/std/re/ temporarily.
# Back up existing files, restore on exit.
BACKUP_DIR="$OUTDIR/lib_std_re_backup"
mkdir -p "$BACKUP_DIR"
cp lib/std/re/*.w "$BACKUP_DIR/" 2>/dev/null || true

restore_lib() {
    cp "$BACKUP_DIR"/*.w lib/std/re/ 2>/dev/null || true
}
trap restore_lib EXIT

# Copy migrated output into lib/std/re/
for f in "$OUTDIR"/*.w; do
    [ -f "$f" ] || continue
    cp "$f" "lib/std/re/$(basename "$f")"
done

# Type-check each migrated file
for f in "$OUTDIR"/*.w; do
    [ -f "$f" ] || continue
    base=$(basename "$f")
    target="lib/std/re/$base"

    set +e
    errs=$("$WITH" check "$target" 2>&1)
    rc=$?
    set -e

    if [ $rc -eq 0 ]; then
        GATE2_PASS_COUNT=$((GATE2_PASS_COUNT + 1))
    else
        GATE2_FAIL_COUNT=$((GATE2_FAIL_COUNT + 1))
        GATE2_FAIL_FILES="$GATE2_FAIL_FILES $base"
        file_errs=$(echo "$errs" | grep -c "^error:" || echo "0")
        GATE2_ERRORS=$((GATE2_ERRORS + file_errs))
        # Capture first 5 errors from this file
        first=$(echo "$errs" | grep "^error:" | head -5)
        if [ -n "$first" ]; then
            GATE2_FIRST_ERRORS="${GATE2_FIRST_ERRORS}
--- $base ($file_errs errors) ---
$first"
        fi
    fi
    echo "$errs" >> "$GATE2_LOG" 2>/dev/null || true
done

# Restore original lib/std/re/
restore_lib

if [ $GATE2_FAIL_COUNT -eq 0 ]; then
    echo "compile: PASS ($GATE2_PASS_COUNT files type-checked)"
else
    echo "compile: FAIL ($GATE2_FAIL_COUNT/$((GATE2_PASS_COUNT + GATE2_FAIL_COUNT)) files failed, $GATE2_ERRORS total errors)"
    OVERALL_EXIT=1
    if [ -n "$GATE2_FIRST_ERRORS" ]; then
        echo "$GATE2_FIRST_ERRORS" | head -60
        total_shown=$(echo "$GATE2_FIRST_ERRORS" | grep -c "^error:" || echo "0")
        if [ "$GATE2_ERRORS" -gt "$total_shown" ]; then
            echo ""
            echo "  ... $((GATE2_ERRORS - total_shown)) more errors in $GATE2_LOG"
        fi
    fi
fi

echo ""

# =========================================================================
# Gate 3: Match (build migrated pcre2test.w, run against testinput1)
# =========================================================================

echo "--- Gate 3: match ---"
echo ""

TESTINPUT=".reference/pcre2/testdata/testinput1"
TESTOUTPUT=".reference/pcre2/testdata/testoutput1"
PCRE2TEST_W="$OUTDIR/pcre2test.w"

if [ ! -f "$TESTINPUT" ] || [ ! -f "$TESTOUTPUT" ]; then
    echo "match:   SKIPPED (test data not found)"
    echo ""
elif [ ! -f "$PCRE2TEST_W" ]; then
    echo "match:   SKIPPED (pcre2test.w not produced by gate 1)"
    echo ""
elif [ $GATE2_FAIL_COUNT -ne 0 ]; then
    echo "match:   SKIPPED (gate 2 failed)"
    echo ""
else
    GATE3_LOG="$OUTDIR/match.log"

    # Stage migrated files into lib/std/re/ for building
    for f in "$OUTDIR"/*.w; do
        [ -f "$f" ] || continue
        cp "$f" "lib/std/re/$(basename "$f")"
    done

    # Build migrated pcre2test.w as a standalone binary.
    # It imports the library modules via use std.re.defs.
    PCRE2TEST_BIN="$OUTDIR/pcre2test"
    set +e
    "$WITH" build "lib/std/re/pcre2test.w" -o "$PCRE2TEST_BIN" 2>"$GATE3_LOG"
    BUILD_RC=$?
    set -e

    # Restore lib/std/re/
    restore_lib

    if [ $BUILD_RC -ne 0 ]; then
        BUILD_ERRS=$(grep -c "^error:" "$GATE3_LOG" 2>/dev/null || echo "0")
        echo "match:   FAIL (pcre2test build failed, $BUILD_ERRS errors)"
        grep "^error:" "$GATE3_LOG" 2>/dev/null | head -20
        if [ "$BUILD_ERRS" -gt 20 ]; then
            echo "  ... $((BUILD_ERRS - 20)) more errors in $GATE3_LOG"
        fi
        OVERALL_EXIT=1
    else
        # Run migrated pcre2test on testinput1
        ACTUAL_OUTPUT="$OUTDIR/testoutput1_actual"
        set +e
        "$PCRE2TEST_BIN" < "$TESTINPUT" > "$ACTUAL_OUTPUT" 2>>"$GATE3_LOG"
        RUN_RC=$?
        set -e

        if [ $RUN_RC -ne 0 ]; then
            echo "match:   FAIL (pcre2test exited $RUN_RC)"
            OVERALL_EXIT=1
        else
            DIFF_OUTPUT="$OUTDIR/testinput1.diff"
            set +e
            diff -u "$TESTOUTPUT" "$ACTUAL_OUTPUT" > "$DIFF_OUTPUT" 2>&1
            DIFF_RC=$?
            set -e

            if [ $DIFF_RC -eq 0 ]; then
                echo "match:   PASS (testinput1)"
            else
                DIFF_LINES=$(wc -l < "$DIFF_OUTPUT" | tr -d ' ')
                echo "match:   FAIL (testinput1, $DIFF_LINES diff lines)"
                head -100 "$DIFF_OUTPUT"
                if [ "$DIFF_LINES" -gt 100 ]; then
                    echo "  ... $((DIFF_LINES - 100)) more lines in $DIFF_OUTPUT"
                fi
                OVERALL_EXIT=1
            fi
        fi
    fi
    echo ""
fi

# =========================================================================
# Summary
# =========================================================================

echo "Full log: $LOGFILE"
echo "========================================"
exit $OVERALL_EXIT
