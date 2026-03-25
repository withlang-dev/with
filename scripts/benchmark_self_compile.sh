#!/bin/bash
# benchmark_self_compile.sh — Measure compiler self-compile time.
# Runs `with-stage2 build src/main.w` 3 times and reports min/median/mean.

set -euo pipefail

COMPILER="${1:-out/bin/with-stage2}"
SOURCE="src/main.w"
TMP_OUT="/tmp/with-bench-$$"
RUNS=3

if [ ! -x "$COMPILER" ]; then
    echo "error: compiler not found at $COMPILER" >&2
    echo "usage: $0 [path-to-compiler]" >&2
    exit 1
fi

echo "Benchmarking: $COMPILER build $SOURCE"
echo "Runs: $RUNS"
echo ""

times=()
for i in $(seq 1 $RUNS); do
    rm -f "$TMP_OUT"
    start=$(python3 -c "import time; print(int(time.time()*1e9))")
    "$COMPILER" build "$SOURCE" -o "$TMP_OUT" 2>/dev/null
    end=$(python3 -c "import time; print(int(time.time()*1e9))")
    elapsed_ms=$(( (end - start) / 1000000 ))
    times+=($elapsed_ms)
    echo "  run $i: ${elapsed_ms}ms"
    rm -f "$TMP_OUT"
done

# Sort times
IFS=$'\n' sorted=($(sort -n <<<"${times[*]}")); unset IFS

min=${sorted[0]}
median=${sorted[$(( RUNS / 2 ))]}
total=0
for t in "${times[@]}"; do total=$((total + t)); done
mean=$((total / RUNS))

echo ""
echo "Results:"
echo "  min:    ${min}ms"
echo "  median: ${median}ms"
echo "  mean:   ${mean}ms"

# Append to history CSV if it exists
HISTORY_FILE="out/log/compile_time_history.csv"
mkdir -p "$(dirname "$HISTORY_FILE")"
if [ ! -f "$HISTORY_FILE" ]; then
    echo "date,commit,min_ms,median_ms,mean_ms" > "$HISTORY_FILE"
fi
commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
echo "$(date +%Y-%m-%d),$commit,$min,$median,$mean" >> "$HISTORY_FILE"
echo ""
echo "Recorded to $HISTORY_FILE"
