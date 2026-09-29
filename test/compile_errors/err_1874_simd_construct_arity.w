//! expect-error: f32x4 takes exactly 4 lane values

// §4.3d (D78, #1874): construction takes exactly N values of T.
fn main:
    let v = f32x4(1, 2, 3)
    print(f"{v[0]}")
