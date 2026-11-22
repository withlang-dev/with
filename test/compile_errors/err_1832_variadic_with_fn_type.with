//! expect-error: only a C function pointer type can be variadic

// #1832: only the `extern "C"` form of a function type can end in `...`;
// a With `fn` value has no C variadic convention.

fn apply(g: fn(i32, ...) -> i32) -> i32: 0

fn main:
    print("x")
