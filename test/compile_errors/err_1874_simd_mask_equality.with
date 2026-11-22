//! expect-error: spell `(m ^ n).any()` or `not (m ^ n)`

// §4.3d (v7.16): `m == n` has two meanings (one bool, or a lane-wise mask)
// and is refused.
fn main:
    let m = m32x4.splat(true)
    let n = m32x4.splat(false)
    print(f"{m == n}")
