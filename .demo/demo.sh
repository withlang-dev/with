#!/bin/bash
# demo.sh — Compare hello world: Rust vs Zig vs With
# Compile time, binary size, output correctness.

set -e

DIR=$(mktemp -d)
cd "$DIR"

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

echo "=== Source ==="
echo ""
echo "--- Rust ---"
cat hello.rs
echo ""
echo "--- Zig ---"
cat hello.zig
echo ""
echo "--- With ---"
cat hello.w
echo ""

echo "=== Compile (cold) ==="
echo ""

# Clear caches
rm -rf ~/.cache/zig 2>/dev/null
export CARGO_INCREMENTAL=0

TIMEFORMAT='%3Rs'

printf "Rust:  "
{ time rustc hello.rs -O -o hello_rs -C incremental=no 2>&1; } 2>&1

printf "Zig:   "
{ time zig build-exe hello.zig -OReleaseSafe -femit-bin=hello_zig 2>/dev/null; } 2>&1

printf "With:  "
{ time with build hello.w -o hello_with 2>/dev/null; } 2>&1

echo ""

strip hello_rs hello_zig hello_with 2>/dev/null

echo "=== Binary size (stripped) ==="
echo ""
printf "Rust:  %6s\n" "$(du -h hello_rs | cut -f1)"
printf "Zig:   %6s\n" "$(du -h hello_zig | cut -f1)"
printf "With:  %6s\n" "$(du -h hello_with | cut -f1)"
echo ""

echo "=== Verify ==="
echo ""
printf "Rust:  "; ./hello_rs
printf "Zig:   "; ./hello_zig
printf "With:  "; ./hello_with
echo ""

rm -rf "$DIR"