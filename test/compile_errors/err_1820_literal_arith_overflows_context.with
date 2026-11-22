//! expect-error: constant arithmetic overflows `u8`

// §4.2.1 / §4.2.3 (#1820): `200 + 100` takes u8 from the binding, and u8
// arithmetic is checked. Its value is known, so it is a compile error, not a
// panic at run time. It was an "implicit narrowing" of an i32 sum.
fn main:
    let x: u8 = 200 + 100
    print(f"{x}")
