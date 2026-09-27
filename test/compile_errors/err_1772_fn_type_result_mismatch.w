//! expect-check-fail: type mismatch in binding

// #1772: a `fn` value is assignable to a `fn` type only when the signatures
// agree. Sema compared only unsafe-ness (types_compatible: TY_FN against
// TY_FN returned callable_unsafe_coercion_ok), so this passed Sema and the
// MIR validator caught it ("use rvalue type is incompatible with assign
// destination").

fn add1(x: i32) -> i32: x + 1

fn main:
    let f: fn(i32) -> str = add1
    print(f(1))
