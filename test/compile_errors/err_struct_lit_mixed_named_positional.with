//! expect-check-fail: expected expression

// §4.3: a struct literal is either all-named or all-positional; mixing them is
// a parse error.

type P { x: i32, y: i32 }

fn main:
    let p = P { 1, y: 2 }
    print_i32(p.x)
