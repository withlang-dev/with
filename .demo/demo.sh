#!/bin/bash
# demo.sh - Hello-world matrix: Rust vs Zig vs With across optimization levels.
# Reports compile time, stripped binary size, and output correctness for each cell.
# Compatible with bash 3.2+ (no associative arrays).

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

# ── Storage helpers (regular variables, no associative arrays) ───

sanitize_level() {
    echo "$1" | tr -c 'A-Za-z0-9' '_'
}

set_cell() {
    local prefix="$1"
    local lang="$2"
    local level="$3"
    local value="$4"
    local safe_level
    safe_level=$(sanitize_level "$level")
    local var_name="${prefix}_${lang}_${safe_level}"
    eval "$var_name=\"\$value\""
}

get_cell() {
    local prefix="$1"
    local lang="$2"
    local level="$3"
    local safe_level
    safe_level=$(sanitize_level "$level")
    local var_name="${prefix}_${lang}_${safe_level}"
    eval "echo \"\${$var_name:-}\""
}

# ── Compile a single (language, level) cell ───────���──────────────

compile_cell() {
    local lang="$1"
    local level="$2"
    local source="$3"
    local out_bin="$4"

    local safe_level
    safe_level=$(sanitize_level "$level")
    local log="$DIR/${lang}_${safe_level}.log"
    local time_file="$DIR/${lang}_${safe_level}.time"

    rm -f "$out_bin"

    case "$lang" in
        Rust)
            local rust_level
            case "$level" in
                0|1|2|3) rust_level="$level" ;;
                *) die "unsupported Rust level: $level" ;;
            esac
            if { time rustc "$source" "-Copt-level=$rust_level" -C incremental=no -o "$out_bin" >"$log" 2>&1; } 2>"$time_file"; then
                :
            else
                compile_secs="FAIL"
                binary_bytes="FAIL"
                return 1
            fi
            ;;
        Zig)
            local zig_mode
            case "$level" in
                Debug)        zig_mode="-ODebug" ;;
                ReleaseSafe)  zig_mode="-OReleaseSafe" ;;
                ReleaseFast)  zig_mode="-OReleaseFast" ;;
                ReleaseSmall) zig_mode="-OReleaseSmall" ;;
                *) die "unsupported Zig level: $level" ;;
            esac
            if { time zig build-exe "$source" "$zig_mode" "${zig_target_args[@]}" "-femit-bin=$out_bin" >"$log" 2>&1; } 2>"$time_file"; then
                :
            else
                compile_secs="FAIL"
                binary_bytes="FAIL"
                return 1
            fi
            ;;
        With)
            local with_level
            case "$level" in
                0|1|2|3) with_level="-O$level" ;;
                ReleaseSafe) with_level="-OReleaseSafe" ;;
                ReleaseFast) with_level="-OReleaseFast" ;;
                *) die "unsupported With level: $level" ;;
            esac
            if { time with build "$source" "$with_level" -o "$out_bin" >"$log" 2>&1; } 2>"$time_file"; then
                :
            else
                compile_secs="FAIL"
                binary_bytes="FAIL"
                return 1
            fi
            ;;
        *)
            die "unknown language: $lang"
            ;;
    esac

    compile_secs=$(awk '{ gsub(/s$/, ""); print $1 }' "$time_file")
    if [ ! -f "$out_bin" ]; then
        compile_secs="FAIL"
        binary_bytes="FAIL"
        return 1
    fi
    strip "$out_bin" >/dev/null 2>&1 || true
    binary_bytes=$(stat -f %z "$out_bin" 2>/dev/null || stat -c %s "$out_bin")
    return 0
}

check_output() {
    local bin="$1"
    local out
    out=$("$bin" 2>&1)
    case "$out" in
        *"Hello, World!"*) echo "OK" ;;
        *) echo "WRONG" ;;
    esac
}

format_size() {
    local bytes="$1"
    if [ "$bytes" = "FAIL" ] || [ -z "$bytes" ]; then
        echo "FAIL"
        return
    fi
    if [ "$bytes" -ge 1048576 ]; then
        awk -v b="$bytes" 'BEGIN { printf "%.1fM", b / 1048576 }'
    else
        awk -v b="$bytes" 'BEGIN { printf "%dK", (b + 512) / 1024 }'
    fi
}

format_compile() {
    local v="$1"
    case "$v" in
        ""|FAIL) echo "${v:-FAIL}" ;;
        *) printf "%.3fs" "$v" ;;
    esac
}

format_output() {
    local v="$1"
    echo "${v:-FAIL}"
}

# ── Setup ──────────────────────────────────────────────��─────────

TIMEFORMAT='%3R'

need_tool rustc
need_tool zig
need_tool with
need_tool strip

zig_target_args=()
zig_target_label="native"
if [ "$(uname -s)" = "Darwin" ]; then
    zig_target_args=(-target native-macos)
    zig_target_label="native-macos"
fi

export CARGO_INCREMENTAL=0
export ZIG_GLOBAL_CACHE_DIR="$DIR/zig-global-cache"
export ZIG_LOCAL_CACHE_DIR="$DIR/zig-local-cache"

cd "$DIR" || exit 1

cat > hello.rs << 'EOF'
fn main() {
    println!("Hello, World!");
}
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

# ── Matrix ───────────────────────────────────────────────────────

RUST_LEVELS="0 1 2 3"
ZIG_LEVELS="Debug ReleaseSafe ReleaseFast ReleaseSmall"
WITH_LEVELS="0 1 2 3 ReleaseSafe ReleaseFast"

run_matrix_for() {
    local lang="$1"
    local source="$2"
    local levels="$3"

    local level
    for level in $levels; do
        printf "  %-6s %-14s ... " "$lang" "$level"

        local safe_level
        safe_level=$(sanitize_level "$level")
        local out_bin="$DIR/${lang}_${safe_level}.bin"

        if compile_cell "$lang" "$level" "$source" "$out_bin"; then
            set_cell COMPILE_TIME "$lang" "$level" "$compile_secs"
            set_cell BINARY_SIZE  "$lang" "$level" "$binary_bytes"

            local output_check
            output_check=$(check_output "$out_bin")
            set_cell OUTPUT "$lang" "$level" "$output_check"

            printf "compile=%ss  size=%s  output=%s\n" \
                "$compile_secs" "$(format_size "$binary_bytes")" "$output_check"
        else
            set_cell COMPILE_TIME "$lang" "$level" "FAIL"
            set_cell BINARY_SIZE  "$lang" "$level" "FAIL"
            set_cell OUTPUT       "$lang" "$level" "FAIL"
            echo "FAIL"
        fi
    done
}

echo "=== Running Matrix ==="
run_matrix_for Rust "$DIR/hello.rs"  "$RUST_LEVELS"
run_matrix_for Zig  "$DIR/hello.zig" "$ZIG_LEVELS"
run_matrix_for With "$DIR/hello.w"   "$WITH_LEVELS"
echo ""

# ── Results: tables ──────────────────────────────────────────────

print_row() {
    local lang="$1"
    local levels="$2"
    local prefix="$3"
    local formatter="$4"

    printf "%-6s" "$lang"
    local level
    for level in $levels; do
        local value
        value=$(get_cell "$prefix" "$lang" "$level")
        printf " %-14s" "$($formatter "$value")"
    done
    echo ""
}

print_header() {
    local label="$1"
    shift
    printf "%-6s" "Lang"
    for col in "$@"; do
        printf " %-14s" "$col"
    done
    echo ""
    printf "%-6s" "----"
    for col in "$@"; do
        printf " %-14s" "--------------"
    done
    echo ""
}

print_compile_table() {
    echo "=== Compile Time ==="
    print_header "Lang" "L0/Debug" "L1/Safe" "L2/Fast" "L3/Small" "ReleaseSafe" "ReleaseFast"
    print_row Rust "$RUST_LEVELS"  COMPILE_TIME format_compile
    print_row Zig  "$ZIG_LEVELS"   COMPILE_TIME format_compile
    print_row With "$WITH_LEVELS"  COMPILE_TIME format_compile
    echo ""
}

print_size_table() {
    echo "=== Binary Size (stripped) ==="
    print_header "Lang" "L0/Debug" "L1/Safe" "L2/Fast" "L3/Small" "ReleaseSafe" "ReleaseFast"
    print_row Rust "$RUST_LEVELS"  BINARY_SIZE format_size
    print_row Zig  "$ZIG_LEVELS"   BINARY_SIZE format_size
    print_row With "$WITH_LEVELS"  BINARY_SIZE format_size
    echo ""
}

print_output_table() {
    echo "=== Output Correctness ==="
    print_header "Lang" "L0/Debug" "L1/Safe" "L2/Fast" "L3/Small" "ReleaseSafe" "ReleaseFast"
    print_row Rust "$RUST_LEVELS"  OUTPUT format_output
    print_row Zig  "$ZIG_LEVELS"   OUTPUT format_output
    print_row With "$WITH_LEVELS"  OUTPUT format_output
    echo ""
}

print_csv() {
    local csv_path="$DIR/results.csv"
    {
        echo "language,level,compile_seconds,binary_bytes,output"
        local level
        for level in $RUST_LEVELS; do
            echo "Rust,$level,$(get_cell COMPILE_TIME Rust $level),$(get_cell BINARY_SIZE Rust $level),$(get_cell OUTPUT Rust $level)"
        done
        for level in $ZIG_LEVELS; do
            echo "Zig,$level,$(get_cell COMPILE_TIME Zig $level),$(get_cell BINARY_SIZE Zig $level),$(get_cell OUTPUT Zig $level)"
        done
        for level in $WITH_LEVELS; do
            echo "With,$level,$(get_cell COMPILE_TIME With $level),$(get_cell BINARY_SIZE With $level),$(get_cell OUTPUT With $level)"
        done
    } > "$csv_path"
    echo "=== CSV ==="
    echo "wrote: $csv_path"
    if [ "${DEMO_VERBOSE:-0}" = "1" ]; then
        echo ""
        cat "$csv_path"
    fi
    KEEP_DIR=1
}

print_compile_table
print_size_table
print_output_table
print_csv
