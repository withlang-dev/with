//! expect-error: cannot bind an array literal to a slice type

// #622: the [T] spelling parses to the same slice type as []T and must reject
// an array-literal initializer identically.
use std.builtins.print_i32
fn main:
    let xs: [i32] = [1, 2, 3]
    print_i32(xs.len() as i32)
