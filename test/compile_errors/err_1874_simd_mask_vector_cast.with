//! expect-error: a true lane could be `1` or `-1`

// §4.3d (v7.16): a cast between a mask and a vector is refused — a true
// lane could be 1 or -1.
fn main:
    let m = m32x4.splat(true)
    let v = m as i32x4
    print(f"{v[0]}")
