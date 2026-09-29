//! expect-error: implicit narrowing

// §4.3d (D78, #1874): an implicit narrowing is refused lane-wise as it is
// for a scalar (§4.2.6); `as` spells it.
fn main:
    let wide = i32x4(1, 2, 3, 4)
    let narrow: Vector[4, i16] = wide
    print(f"{narrow[0]}")
