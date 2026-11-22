//! expect-stdout: 3
//! expect-stdout: 2
//! expect-stdout: 1

use std.builtins.write
fn main:
    defer: write("1\n")
    defer:
        write("2\n")
    defer {
        write("3\n")
    }
