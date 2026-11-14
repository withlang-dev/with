//! expect-build-fail: cannot cast `str` to `bool`: a text has no numeric value to convert

// Test: a cast from text to a type that does not implement `Parse` is
// refused by Sema (#2043, D65: acceptance is Sema's). It once reached MIR
// and failed as "invalid MIR before codegen: unsupported cast in MIR".
// Text to a `Parse` type is the conversion of §15.5 (D204), so this is
// `bool`, where it was `i32` before that ruling.

fn main:
    let s = "hello"
    let x = s as bool
    print(x)
