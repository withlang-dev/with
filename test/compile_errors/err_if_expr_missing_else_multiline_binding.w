//! expect-check-fail: if expression requires an else branch unless the then branch diverges

fn main:
    let _x =
        if true: 5
