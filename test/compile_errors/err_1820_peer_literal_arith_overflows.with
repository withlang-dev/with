//! expect-error: constant arithmetic overflows `i8`

// §4.2.1 rule 3 (#1820): `(100 + 100)` takes i8 from the peer operand `y`,
// as a bare literal does. It was i32 arithmetic and `y + 200` an i32 sum.
fn main:
    let y: i8 = 1
    let z = y + (100 + 100)
    print(f"{z}")
