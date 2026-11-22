//! check-only
fn apply(f: fn(i32) -> i32, x: i32) -> i32:
    f(x)

fn test_bool(f: fn(i32) -> bool, x: i32) -> bool:
    f(x)

fn main:
    let a = apply(it * 2, 21)
    let b = apply(it + 1, 5)
    let c = apply(-it, 3)
    let d = test_bool(it > 0, 5)
