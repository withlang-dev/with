//! expect-debug-alloc: leak count=0 allocations=0
//! expect-stdout: 42
// The exit report is unconditional: a program that never allocates still
// prints its verdict and says it saw zero allocations. It printed nothing,
// which no reader could tell from the debug allocator not running.
use std.builtins.print_i32

fn main:
    print_i32(6 * 7)
