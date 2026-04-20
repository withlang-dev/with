#!/bin/bash
# ecs_bench.sh - ECS benchmark: Rust vs Zig vs With.
# Reports source lines, compile time, stripped binary size, and benchmark output.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR=$(mktemp -d)
KEEP_DIR=0

cleanup() {
    if [ "$KEEP_DIR" -eq 0 ]; then
        rm -rf "$WORK_DIR"
    else
        echo ""
        echo "kept work dir: $WORK_DIR"
    fi
}
trap cleanup EXIT

die() {
    echo "error: $*" >&2
    exit 1
}

need_tool() {
    command -v "$1" >/dev/null 2>&1 || die "missing required tool: $1"
}

line_count() {
    wc -l < "$1" | tr -d ' '
}

print_failure_summary() {
    local log="$1"

    if [ ! -s "$log" ]; then
        echo "  compiler produced no diagnostic output"
        return
    fi

    local summary
    summary=$(grep -E '^(error|fatal|ld:|clang:|zig ld|note:)' "$log" | head -12)
    if [ -z "$summary" ]; then
        summary=$(head -12 "$log")
    fi

    echo "$summary" | sed 's/^/  /'

    local total
    total=$(wc -l < "$log" | tr -d ' ')
    if [ "$total" -gt 12 ]; then
        echo "  ... ($((total - 12)) more lines; set DEMO_VERBOSE=1 for full output)"
    fi
}

run_compile() {
    local label="$1"
    shift

    local log="$WORK_DIR/${label}.log"
    local time_log="$WORK_DIR/${label}.time"

    printf "%-6s " "$label:"
    if { time "$@" >"$log" 2>&1; } 2>"$time_log"; then
        cat "$time_log"
        if [ "${DEMO_VERBOSE:-0}" = "1" ] && [ -s "$log" ]; then
            sed "s/^/  [$label] /" "$log"
        fi
    else
        echo "FAILED"
        echo "  command: $*"
        print_failure_summary "$log"
        if [ "${DEMO_VERBOSE:-0}" = "1" ]; then
            echo ""
            echo "full compiler output:"
            sed 's/^/  /' "$log"
        fi
        KEEP_DIR=1
        exit 1
    fi
}

run_bench() {
    local label="$1"
    local bin="$2"

    echo "=== Runtime: $label ==="
    if "$bin"; then
        echo ""
    else
        echo "error: $label benchmark exited with status $?" >&2
        KEEP_DIR=1
        exit 1
    fi
}

TIMEFORMAT='%3Rs'

need_tool rustc
need_tool zig
need_tool with
need_tool strip

zig_target_args=()
zig_target_label="native"
if [ "$(uname -s)" = "Darwin" ]; then
    # Zig 0.15 can infer macOS 26.x native targets that fail to link libSystem.
    # native-macos keeps the host architecture while letting Zig choose a stable
    # macOS deployment range.
    zig_target_args=(-target native-macos)
    zig_target_label="native-macos"
fi

RS_BIN="$WORK_DIR/ecs_rs"
ZIG_BIN="$WORK_DIR/ecs_zig"
WITH_BIN="$WORK_DIR/ecs_with"

echo "=== Tools ==="
printf "Rust:  %s\n" "$(rustc --version)"
printf "Zig:   zig %s (target %s)\n" "$(zig version)" "$zig_target_label"
printf "With:  %s\n" "$(with version 2>/dev/null || echo with)"
echo ""

echo "=== Source Lines ==="
printf "Rust:  %4d lines\n" "$(line_count "$SCRIPT_DIR/ecs_bench.rs")"
printf "Zig:   %4d lines\n" "$(line_count "$SCRIPT_DIR/ecs_bench.zig")"
printf "With:  %4d lines\n" "$(line_count "$SCRIPT_DIR/ecs_bench.w")"
echo ""

echo "=== Compile ==="
export CARGO_INCREMENTAL=0
export ZIG_GLOBAL_CACHE_DIR="$WORK_DIR/zig-global-cache"
export ZIG_LOCAL_CACHE_DIR="$WORK_DIR/zig-local-cache"

run_compile Rust rustc "$SCRIPT_DIR/ecs_bench.rs" -O -o "$RS_BIN" -C incremental=no
run_compile Zig zig build-exe "$SCRIPT_DIR/ecs_bench.zig" -OReleaseFast "${zig_target_args[@]}" -femit-bin="$ZIG_BIN"
run_compile With with build "$SCRIPT_DIR/ecs_bench.w" -o "$WITH_BIN"
echo ""

strip "$RS_BIN" "$ZIG_BIN" "$WITH_BIN" >/dev/null 2>&1 || true

echo "=== Binary Size (stripped) ==="
printf "Rust:  %6s\n" "$(du -h "$RS_BIN" | cut -f1)"
printf "Zig:   %6s\n" "$(du -h "$ZIG_BIN" | cut -f1)"
printf "With:  %6s\n" "$(du -h "$WITH_BIN" | cut -f1)"
echo ""

run_bench Rust "$RS_BIN"
run_bench Zig "$ZIG_BIN"
run_bench With "$WITH_BIN"
