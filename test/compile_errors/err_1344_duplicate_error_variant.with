//! expect-check-fail: duplicate variant `A` in `E`

// #1344: the `error E = | A | A` spelling is the same enum declaration.

error E = | A | A

fn main:
    let e = E.A
    match e:
        .A => print("a")
