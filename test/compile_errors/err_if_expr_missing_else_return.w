//! expect-check-fail: if expression requires an else branch unless the then branch diverges

fn f() -> i32:
    if true: 5

fn main:
    let _x = f()
