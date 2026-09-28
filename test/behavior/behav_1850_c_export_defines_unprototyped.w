//! expect-stdout: 42
//! expect-stdout: 25

// #1850, §16.5: a `@[c_export]` definition of a symbol a c_imported header
// declares without a prototype (`int zz_knr();`) is that function: C calls
// it with promoted arguments and the fixed-argument convention (#1831),
// which is what the definition takes. The prototype's LLVM declaration had
// another type, so the definition moved it aside and every call kept the
// renamed declaration: undefined `_knr_impl__stale_decl` at link.
use c_import("int zz_knr();\n")

@[c_export("zz_knr")]
fn knr_impl(a: c_int, b: f64) -> c_int: a * 10 + (b * 10.0) as c_int

fn narrow(x: i8) -> i8: x
fn single(x: f32) -> f32: x

fn main:
    print(unsafe { zz_knr(4, 0.2) })
    print(unsafe { zz_knr(narrow(2), single(0.5)) })
