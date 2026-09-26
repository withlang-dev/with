//! expect-check-fail: duplicate variant `A` in `E`

// #1344: a variant listed twice gave `E.A` two meanings; the compiler
// picked one silently.

enum E:
    A
    A

fn main:
    let e = E.A
    match e:
        .A => print("a")
