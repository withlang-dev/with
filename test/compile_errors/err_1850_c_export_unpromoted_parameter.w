//! expect-error: which a promoted argument never is

// #1850, C11 6.7.6.3p15: a definition of a function declared without a
// prototype takes the promoted arguments C passes; an `f32` parameter
// (C passes a double) is a conflicting definition.
use c_import("int zz_knr();\n")

@[c_export("zz_knr")]
fn knr_impl(a: c_int, b: f32) -> c_int: a

fn main:
    print(unsafe { zz_knr(4, 0.5) })
