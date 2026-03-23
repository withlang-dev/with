#!/bin/bash
# ecs_bench.sh — ECS benchmark: Rust vs Zig vs With
# Measures SLOC, compile time, binary size, and runtime performance.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Source Lines ==="
echo ""
printf "Rust:  %4d lines\n" "$(wc -l < "$SCRIPT_DIR/ecs_bench.rs")"
printf "Zig:   %4d lines\n" "$(wc -l < "$SCRIPT_DIR/ecs_bench.zig")"
printf "With:  %4d lines\n" "$(wc -l < "$SCRIPT_DIR/ecs_bench.w")"
echo ""

echo "=== Compile ==="
echo ""

rm -rf ~/.cache/zig 2>/dev/null
export CARGO_INCREMENTAL=0
TIMEFORMAT='%3Rs'

printf "Rust:  "
{ time rustc "$SCRIPT_DIR/ecs_bench.rs" -O -o /tmp/ecs_rs 2>&1; } 2>&1

printf "Zig:   "
{ time zig build-exe "$SCRIPT_DIR/ecs_bench.zig" -OReleaseFast -femit-bin=/tmp/ecs_zig 2>/dev/null; } 2>&1

printf "With:  "
{ time with build "$SCRIPT_DIR/ecs_bench.w" -o /tmp/ecs_with 2>/dev/null; } 2>&1

echo ""

strip /tmp/ecs_rs /tmp/ecs_zig /tmp/ecs_with 2>/dev/null

echo "=== Binary Size (stripped) ==="
echo ""
printf "Rust:  %6s\n" "$(du -h /tmp/ecs_rs | cut -f1)"
printf "Zig:   %6s\n" "$(du -h /tmp/ecs_zig | cut -f1)"
printf "With:  %6s\n" "$(du -h /tmp/ecs_with | cut -f1)"
echo ""

echo "=== Runtime: Rust ==="
/tmp/ecs_rs
echo ""

echo "=== Runtime: Zig ==="
/tmp/ecs_zig
echo ""

echo "=== Runtime: With ==="
/tmp/ecs_with
echo ""

rm -f /tmp/ecs_rs /tmp/ecs_zig /tmp/ecs_with
