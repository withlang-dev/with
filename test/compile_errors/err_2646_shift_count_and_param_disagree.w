//! expect-check-fail: a local's uses must agree on its type

// D160 (§4.2.1): a shift count demands `u32` of the literal-typed local it
// reads; a later use that demands `i32` of it disagrees, naming both.
fn narrow(x: i32): ()

fn main:
    let v: i64 = 0x1234
    let s = 8
    print(v >> s)
    narrow(s)
