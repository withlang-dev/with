//! expect-error: `m32x4.bits()` is refused

// §4.3d (v7.16): `.bits()` on a mask is refused — a true lane as bits is
// 1 or -1.
fn main:
    let m = m32x4.splat(true)
    let b = m.bits()
    print(f"{b[0]}")
