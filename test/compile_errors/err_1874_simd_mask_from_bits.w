//! expect-error: `m32x4.from_bits` is refused

// §4.3d (v7.16): `.from_bits` on a mask is refused — a true lane from bits
// could be 1 or -1.
fn main:
    let m = m32x4.from_bits(u32x4.splat(1))
    print(f"{m[0]}")
