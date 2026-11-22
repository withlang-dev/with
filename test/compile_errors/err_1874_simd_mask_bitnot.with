//! expect-error: `not m` is the one spelling

// §4.3d (v7.16): `~m` is refused; `not m` negates a mask.
fn main:
    let m = m32x4.splat(true)
    let n = ~m
    print(f"{n.any()}")
