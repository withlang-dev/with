//! expect-error: lane-wise operator needs vectors of the same shape

// §4.3d (D78, #1874): operators are lane-wise, so the shapes agree.
fn main:
    let a = f32x4(1, 2, 3, 4)
    let b = f32x8(1, 2, 3, 4, 5, 6, 7, 8)
    let c = a + b
    print(f"{c[0]}")
