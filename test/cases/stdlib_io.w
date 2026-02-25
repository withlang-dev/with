// Test: std.io import
use std.io

fn main() -> i32 =
    // Basic stdout output
    print_str("hello ")
    print_line("world")
    print_int(42)
    print_float(3.14)

    println("all stdlib io tests passed")
    0
