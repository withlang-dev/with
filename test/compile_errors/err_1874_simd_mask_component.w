//! expect-error: a mask's lanes are `m[i]`

// §4.3d (v7.16): `.x`-style components are refused on a mask; its lanes
// are `m[i]`.
fn main:
    let m = m32x4.splat(true)
    print(f"{m.x}")
