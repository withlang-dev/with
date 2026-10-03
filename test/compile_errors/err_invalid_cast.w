//! expect-build-fail: cannot cast `str` to `i32`: a text has no numeric value to convert

// Test: a cast from str to i32 is refused by Sema (#2043, D65: acceptance
// is Sema's). It once reached MIR and failed as "invalid MIR before
// codegen: unsupported cast in MIR".

use std.builtins.int_to_string
fn main:
    let s = "hello"
    let x = s as i32
    print(int_to_string(x))
