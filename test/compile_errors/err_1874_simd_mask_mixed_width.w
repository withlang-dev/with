//! expect-error: masks of different widths do not combine

// §4.3d (D80, #1874): masks of different widths do not combine;
// `m as m8x4` converts the width.
fn main:
    let a = i32x4(1, 2, 3, 4) > 2
    let b = Vector[4, i8](1, 2, 3, 4) > 2
    let c = a & b
    print(f"{c.any()}")
