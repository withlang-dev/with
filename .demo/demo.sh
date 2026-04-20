#!/bin/bash
# demo.sh - Compare hello world: Rust vs Zig vs With.
# Reports source size, cold compile time, stripped binary size, and output.

set -u

DIR=$(mktemp -d)
KEEP_DIR=0

cleanup() {
    if [ "$KEEP_DIR" -eq 0 ]; then
        rm -rf "$DIR"
    else
        echo ""
        echo "kept work dir: $DIR"
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

byte_count() {
    wc -c < "$1" | tr -d ' '
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

    local log="$DIR/${label}.log"
    local time_log="$DIR/${label}.time"

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

TIMEFORMAT='%3Rs'

need_tool rustc
need_tool zig
need_tool with
need_tool strip

cd "$DIR" || exit 1

cat > hello.rs << 'EOF'
fn main() { println!("Hello, World!"); }
EOF

cat > hello.zig << 'EOF'
const std = @import("std");
pub fn main() void {
    std.debug.print("Hello, World!\n", .{});
}
EOF

cat > hello.w << 'EOF'
fn main:
    print("Hello, World!")
EOF

zig_target_args=()
zig_target_label="native"
if [ "$(uname -s)" = "Darwin" ]; then
    # Zig 0.15 can infer macOS 26.x native targets that fail to link libSystem.
    # native-macos keeps the host architecture while letting Zig choose a stable
    # macOS deployment range.
    zig_target_args=(-target native-macos)
    zig_target_label="native-macos"
fi

echo "=== Tools ==="
printf "Rust:  %s\n" "$(rustc --version)"
printf "Zig:   zig %s (target %s)\n" "$(zig version)" "$zig_target_label"
printf "With:  %s\n" "$(with version 2>/dev/null || echo with)"
echo ""

echo "=== Source ==="
printf "Rust:  %s lines, %s bytes\n" "$(line_count hello.rs)" "$(byte_count hello.rs)"
printf "Zig:   %s lines, %s bytes\n" "$(line_count hello.zig)" "$(byte_count hello.zig)"
printf "With:  %s lines, %s bytes\n" "$(line_count hello.w)" "$(byte_count hello.w)"
echo ""
echo "--- With source ---"
cat hello.w
echo ""

echo "=== Compile (cold) ==="
export CARGO_INCREMENTAL=0
export ZIG_GLOBAL_CACHE_DIR="$DIR/zig-global-cache"
export ZIG_LOCAL_CACHE_DIR="$DIR/zig-local-cache"

run_compile Rust rustc hello.rs -O -o hello_rs -C incremental=no
run_compile Zig zig build-exe hello.zig -OReleaseSafe "${zig_target_args[@]}" -femit-bin=hello_zig
run_compile With with build hello.w -o hello_with
echo ""

strip hello_rs hello_zig hello_with >/dev/null 2>&1 || true

echo "=== Binary size (stripped) ==="
printf "Rust:  %6s\n" "$(du -h hello_rs | cut -f1)"
printf "Zig:   %6s\n" "$(du -h hello_zig | cut -f1)"
printf "With:  %6s\n" "$(du -h hello_with | cut -f1)"
echo ""

echo "=== Output ==="
printf "Rust:  "; ./hello_rs
printf "Zig:   "; ./hello_zig
printf "With:  "; ./hello_with
