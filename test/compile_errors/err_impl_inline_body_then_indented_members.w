//! expect-check-fail: an inline impl body is a single member

// #1346 (§29.13 Form 1): an inline impl body is one member and ends at the
// end of the header line; the indented `fn b` is outside it.

type X { v: i32 }

impl X: fn a(): 1
    fn b(): 2

fn main:
    let x = X { v: 0 }
    print(f"{x.a() + x.b()}")
