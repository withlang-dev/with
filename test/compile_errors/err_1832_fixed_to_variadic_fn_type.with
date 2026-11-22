//! expect-check-fail: type mismatch in binding

// #1832: variadic-ness is part of a function type's identity: a fixed-arity
// C function is not a variadic one (another calling convention).

extern "C" fn abs(x: i32) -> i32

fn main:
    let f: extern "C" fn(i32, ...) -> i32 = abs
    print("x")
