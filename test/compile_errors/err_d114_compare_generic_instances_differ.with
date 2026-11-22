//! expect-check-fail: comparison operands must have the same type: `Option[i32]` and `Option[isize]`

// #1368 (§4.2.6): two instances of one generic type whose payloads differ
// do not compare; a payload does not convert. `b` is an Option[isize]
// (D114: locals are not typed by their uses), and the comparison once
// reached MIR as operands of incompatible types.
fn main:
    let a: Option[i32] = None
    let b = Some(1)
    print(a < b)
