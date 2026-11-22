//! expect-error: an `extern "C" fn` type cannot return an array

// #1975 (C11 6.7.6.3p1: "a function declarator shall not specify a return
// type that is ... an array type"): no C function type returns an array,
// so the C ABI has no spelling for this type.
fn arr() -> [u16; 2]: [1, 2]

fn main:
    let f: extern "C" fn() -> [u16; 2] = arr
    print("x")
