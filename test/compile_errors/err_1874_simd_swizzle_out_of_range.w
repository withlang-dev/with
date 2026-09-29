//! expect-error: swizzle component `z` names lane 2 of a 2-lane vector

// §4.3d (D78, #1874): a swizzle names lanes the vector has.
fn main:
    let v = f64x2(1, 2)
    let w = v.xz
    print(f"{w[0]}")
