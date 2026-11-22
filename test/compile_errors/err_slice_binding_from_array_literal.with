//! expect-error: cannot bind an array literal to a slice type

// #622: binding an array literal to a slice type used to be accepted and then
// bit-reinterpreted the array as a slice header (len read element[1]) — silent
// corruption and an out-of-bounds read on index. Both the []T and [T] spellings
// must be rejected.
use std.builtins.print_i32
fn main:
    let xs: []i32 = [1, 2, 3]
    print_i32(xs.len() as i32)
