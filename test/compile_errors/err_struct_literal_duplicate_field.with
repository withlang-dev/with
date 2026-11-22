//! expect-check-fail: duplicate field 'x' in struct literal
// §4.3: a struct literal may not initialize the same field twice.
type P { x: i32, y: i32 }

fn main:
    let _p = P { x: 1, x: 2, y: 3 }
