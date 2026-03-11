//! expect-error: `it` used in context expecting 2 parameter(s)

fn apply2(f: fn(i32, i32) -> i32) -> i32:
    f(1, 2)

fn main:
    let r = apply2(it + 1)
    println("{r}")
